#!/usr/bin/env python3
"""Copilot hooks: conservative, audit-first, no deployments or repository changes."""
import json
import os
import re
import sys
from pathlib import Path

MAX_BYTES = 1024 * 1024

def output(obj=None):
    print(json.dumps(obj or {}))

def event_input():
    try:
        data = json.load(sys.stdin)
        return data if isinstance(data, dict) else {}
    except (ValueError, OSError):
        return {}

def tool_args(event):
    args = event.get('toolArgs', event.get('tool_input', {}))
    if isinstance(args, str):
        try:
            args = json.loads(args)
        except ValueError:
            args = {'command': args}
    return args if isinstance(args, dict) else {}

def command_from(event, args):
    name = str(event.get('toolName', event.get('tool_name', ''))).lower()
    if not any(x in name for x in ('terminal', 'bash', 'shell', 'run', 'execute', 'powershell')):
        return ''
    return str(args.get('command', args.get('cmd', args.get('script', ''))))

def paths_from(event, args):
    cwd = Path(event.get('cwd') or os.getcwd()).resolve()
    if not cwd.is_dir():
        return []
    values = []
    for key in ('filePath', 'file_path', 'path', 'targetFile', 'target_file'):
        v = args.get(key)
        if isinstance(v, str): values.append(v)
    result = []
    for v in values[:5]:
        p = Path(v).expanduser()
        if not p.is_absolute(): p = cwd / p
        try:
            p = p.resolve(strict=True)
            if p.is_file() and p.stat().st_size <= MAX_BYTES:
                result.append(p)
        except (OSError, ValueError):
            pass
    return result

def read_text(path):
    try: return path.read_text(encoding='utf-8')
    except (OSError, UnicodeError): return ''

def git_guard(event, args):
    cmd = command_from(event, args)
    if not cmd: return {}
    checks = [
        ('hard reset', r'\bgit\s+(?:-C\s+\S+\s+)?reset\s+--hard\b'),
        ('forced clean', r'\bgit\s+clean\s+-[^\s]*f'),
        ('branch deletion', r'\bgit\s+branch\s+-[dD]\b'),
        ('rebase skip', r'\bgit\s+rebase\s+--skip\b'),
        ('force push', r'\bgit\s+push\b[^\n;|&]*\s--force(?:\s|$)'),
        ('remote branch deletion', r'\bgit\s+push\b[^\n;|&]*\s--delete\b'),
        ('protected branch push', r'\bgit\s+push\s+\S+\s+(?:main|master|develop)(?:\s|$)'),
    ]
    hits = [name for name, pattern in checks if re.search(pattern, cmd, re.I)]
    if hits:
        return {'permissionDecision':'ask', 'permissionDecisionReason':
                'Git Safety Guard: review '+', '.join(hits)+'. Confirm branch, remote and recovery plan.'}
    return {}

def pipeline(path, text):
    if path.suffix.lower() not in ('.yml','.yaml'): return []
    if not ('pipeline' in path.name.lower() or 'pipelines' in [s.lower() for s in path.parts]): return []
    notes = []
    if re.search(r'(?im)^\s*(?:trigger|pr|stages|jobs|steps)\s*:', text) is None:
        notes.append('No common Azure Pipelines root key detected (may be a template).')
    if re.search(r'(?i)\b(?:password|clientSecret|accessKey)\s*:\s*["\x27]?[A-Za-z0-9+/=_-]{12,}', text):
        notes.append('Possible hardcoded credential; review securely.')
    try:
        import yaml
        class UniqueLoader(yaml.SafeLoader): pass
        def mapping(loader, node):
            pairs = loader.construct_pairs(node, deep=True)
            keys = [k for k,_ in pairs]
            if len(keys) != len(set(map(str,keys))): raise ValueError('Duplicate YAML mapping key')
            return dict(pairs)
        UniqueLoader.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, mapping)
        list(yaml.load_all(text, Loader=UniqueLoader))
    except ImportError:
        notes.append('PyYAML not installed; YAML parser check skipped.')
    except Exception:
        notes.append('YAML syntax or duplicate-key check failed.')
    return notes

def terraform(path, text):
    if path.suffix.lower() != '.tf': return []
    notes=[]
    rules=[
      ('Possible public ingress from all IPv4 addresses', r'(?is)cidr_blocks\s*=\s*\[[^\]]*0\.0\.0\.0/0'),
      ('TLS verification disabled', r'(?i)insecure\s*=\s*true'),
      ('Public access enabled', r'(?i)(?:public_network_access_enabled|allow_blob_public_access)\s*=\s*true'),
      ('Hardcoded sensitive value', r'(?i)(?:client_secret|password|access_key)\s*=\s*"[^"\n]{8,}"'),
    ]
    for label, pat in rules:
        if re.search(pat,text): notes.append(label)
    return notes

def kubernetes(path, text):
    if path.suffix.lower() not in ('.yaml','.yml'): return []
    if not re.search(r'(?m)^\s*kind\s*:\s*(?:Pod|Deployment|DaemonSet|StatefulSet|Job|CronJob)\b',text): return []
    notes=[]
    checks=[
      ('Privileged container', r'(?i)privileged\s*:\s*true'),
      ('Host networking enabled', r'(?i)hostNetwork\s*:\s*true'),
      ('Host PID enabled', r'(?i)hostPID\s*:\s*true'),
      ('Explicit root user', r'(?i)runAsUser\s*:\s*0\b'),
      ('Privilege escalation enabled', r'(?i)allowPrivilegeEscalation\s*:\s*true'),
      ('Latest image tag', r'(?im)^\s*image\s*:\s*\S+:latest\s*$'),
    ]
    for label,pat in checks:
        if re.search(pat,text): notes.append(label)
    return notes

def bicep(path, text):
    if path.suffix.lower() != '.bicep': return []
    notes=[]
    checks=[
      ('Hardcoded password or secret', r'(?im)^\s*(?:param|var)\s+(?:password|clientSecret|adminPassword)\s+\w+\s*=\s*[\x27"][^\n\x27"]+[\x27"]'),
      ('Potential unrestricted inbound access', r'(?is)sourceAddressPrefix\s*:\s*[\x27"]\*[\x27"]'),
      ('Public network access explicitly enabled', r'(?i)publicNetworkAccess\s*:\s*[\x27"]Enabled[\x27"]'),
    ]
    for label,pat in checks:
        if re.search(pat,text): notes.append(label)
    return notes

def main():
    if len(sys.argv) != 2:
        output(); return
    mode=sys.argv[1]
    event=event_input()
    args=tool_args(event)
    if mode=='git':
        output(git_guard(event,args)); return
    findings=[]
    for path in paths_from(event,args):
        text=read_text(path)
        if not text: continue
        if mode=='pipeline': notes=pipeline(path,text)
        elif mode=='terraform': notes=terraform(path,text)
        elif mode=='kubernetes': notes=kubernetes(path,text)
        elif mode=='bicep': notes=bicep(path,text)
        else: notes=[]
        findings.extend(f'{path.name}: {n}' for n in notes)
    if findings:
        # Do not include file contents or credentials in hook output.
        output({'additionalContext':f'{mode} audit (non-blocking): '+'; '.join(findings[:10])})
    else: output()

if __name__=='__main__': main()

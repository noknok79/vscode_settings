#!/usr/bin/env python3
import json, re, sys

def main():
    try: event = json.load(sys.stdin)
    except (ValueError, OSError): print('{}'); return
    name = str(event.get('toolName', event.get('tool_name', ''))).lower()
    if not any(x in name for x in ('bash','powershell','terminal','execute','run')):
        print('{}'); return
    args = event.get('toolArgs', event.get('tool_input', {}))
    if isinstance(args, str):
        try: args = json.loads(args)
        except ValueError: pass
    if isinstance(args, dict):
        command = ' '.join(str(args.get(k,'')) for k in ('command','cmd','script','code'))
    else: command = str(args)
    rules = [
        ('destructive Git reset', r'\bgit\s+reset\s+--hard\b'),
        ('destructive Git clean', r'\bgit\s+clean\s+-(?:[a-zA-Z]*f[a-zA-Z]*d|[a-zA-Z]*d[a-zA-Z]*f)'),
        ('unconditional force push', r'\bgit\s+push\b[^\n;&|]*\s--force(?:\s|$)'),
        ('Terraform destroy', r'\bterraform\s+destroy\b'),
        ('Kubernetes delete', r'\bkubectl\s+delete\b'),
        ('Azure resource group delete', r'\baz\s+group\s+delete\b'),
    ]
    hits = [label for label, pattern in rules if re.search(pattern, command, re.I)]
    if hits:
        print(json.dumps({'permissionDecision':'ask','permissionDecisionReason':'Review potentially destructive command: '+', '.join(hits)+'.'}))
    else: print('{}')

if __name__ == '__main__': main()

#!/usr/bin/env python3
"""Post-tool audit-only checks. Never changes files or launches deployment commands."""
import json, os, re, shutil, subprocess, sys
from pathlib import Path

def main():
    try: event = json.load(sys.stdin)
    except (ValueError, OSError): print('{}'); return
    args = event.get('toolArgs', event.get('tool_input', {}))
    if isinstance(args, str):
        try: args = json.loads(args)
        except ValueError: args = {'text':args}
    if not isinstance(args, dict): print('{}'); return
    cwd = Path(event.get('cwd') or os.getcwd()).resolve()
    if not cwd.is_dir(): print('{}'); return
    candidates = []
    for key in ('filePath','file_path','path','targetFile','target_file'):
        val = args.get(key)
        if isinstance(val, str): candidates.append(val)
    # Deliberately do not parse shell command text or recursively scan repositories.
    notes = []
    for item in candidates[:5]:
        path = Path(item)
        if not path.is_absolute(): path = cwd/path
        path = path.resolve()
        if not path.is_file() or path.stat().st_size > 2_000_000: continue
        if path.suffix == '.tf' and shutil.which('terraform'):
            cmd = ['terraform','fmt','-check',str(path)]
        elif path.suffix in ('.yaml','.yml'):
            try:
                import yaml
            except ImportError:
                continue
            try:
                with path.open(encoding='utf-8') as stream:
                    list(yaml.safe_load_all(stream))
            except Exception:
                notes.append(f'YAML parse check failed: {path.name}')
            continue
        else:
            continue
        try:
            result = subprocess.run(cmd, cwd=str(cwd), capture_output=True, text=True, timeout=8)
            if result.returncode: notes.append(f'Terraform formatting check failed: {path.name}')
        except (OSError, subprocess.TimeoutExpired):
            notes.append(f'Terraform check unavailable: {path.name}')
    if notes:
        print(json.dumps({'additionalContext':'IaC audit (non-blocking): '+'; '.join(notes)}))
    else: print('{}')

if __name__ == '__main__': main()

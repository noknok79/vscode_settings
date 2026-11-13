#!/usr/bin/env python3
import json, re, sys

def emit(obj):
    print(json.dumps(obj))

def main():
    try:
        event = json.load(sys.stdin)
    except (ValueError, OSError):
        emit({}); return
    args = event.get('toolArgs', event.get('tool_input', {}))
    if isinstance(args, str):
        try: args = json.loads(args)
        except ValueError: pass
    text = json.dumps(args) if not isinstance(args, str) else args
    patterns = [
        ('private key material', r'-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----'),
        ('GitHub token', r'\b(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{20,}\b'),
        ('GitHub fine-grained token', r'\bgithub_pat_[A-Za-z0-9_]{20,}\b'),
        ('Azure storage connection string', r'AccountKey\s*=\s*[A-Za-z0-9+/]{30,}={0,2}'),
        ('credential assignment', r'(?i)\b(?:client_secret|api_key|access_token|password)\s*[:=]\s*["\x27]?[A-Za-z0-9_+/.=-]{16,}')
    ]
    hits = [label for label, pattern in patterns if re.search(pattern, text)]
    if hits:
        emit({'permissionDecision':'ask','permissionDecisionReason':'Potential secret in tool arguments ('+', '.join(hits)+'). Review/redact before proceeding.'})
    else: emit({})

if __name__ == '__main__': main()

#!/usr/bin/env python3

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

LOG_FILE = Path("/root/.copilot/hooks/devops-audit.log")

try:
    event = json.load(sys.stdin)

    tool_name = event.get("toolName", "unknown")

    timestamp = datetime.now(timezone.utc).isoformat()

    with LOG_FILE.open("a", encoding="utf-8") as log:
        log.write(f"{timestamp} | {tool_name}\n")

except Exception:
    pass

print("{}")

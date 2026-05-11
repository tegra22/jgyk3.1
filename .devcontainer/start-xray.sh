#!/bin/sh
set -eu

UUID_FILE="${HOME}/.xray-uuid"
if [ ! -f "$UUID_FILE" ]; then
  cat /proc/sys/kernel/random/uuid > "$UUID_FILE"
fi
XRAY_UUID="$(cat "$UUID_FILE")"
export XRAY_UUID
XRAY_PROCESS_PATTERN="/usr/local/bin/xray -c /tmp/config.runtime.json"

python3 - <<'PY'
import json
import os
from pathlib import Path

config_path = Path("/etc/config.json")
runtime_path = Path("/tmp/config.runtime.json")
uuid_value = os.environ["XRAY_UUID"].strip()
data = json.loads(config_path.read_text())
data["inbounds"][0]["settings"]["clients"][0]["id"] = uuid_value
runtime_path.write_text(json.dumps(data, indent=2) + "\n")
PY

cat > /opt/mrh-admin/xray-info.json <<EOF
{"uuid":"$XRAY_UUID","path":"/","remark":"ghtun"}
EOF

if ! pgrep -f "$XRAY_PROCESS_PATTERN" >/dev/null; then
  START_CMD="/usr/local/bin/xray -c /tmp/config.runtime.json"
  if sudo -n true >/dev/null 2>&1; then
    sudo nohup $START_CMD >/tmp/xray.log 2>&1 &
  else
    nohup $START_CMD >/tmp/xray.log 2>&1 &
  fi
fi

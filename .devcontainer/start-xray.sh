#!/bin/sh
set -eu

UUID_FILE="${HOME}/.xray-uuid"
if [ ! -f "$UUID_FILE" ]; then
  cat /proc/sys/kernel/random/uuid > "$UUID_FILE"
fi
XRAY_UUID="$(cat "$UUID_FILE")"
XRAY_PROCESS_PATTERN="/usr/local/bin/xray -c /tmp/config.runtime.json"

python3 - <<'PY'
import json
from pathlib import Path

config_path = Path("/etc/config.json")
runtime_path = Path("/tmp/config.runtime.json")
uuid_value = Path.home().joinpath(".xray-uuid").read_text().strip()
data = json.loads(config_path.read_text())
data["inbounds"][0]["settings"]["clients"][0]["id"] = uuid_value
runtime_path.write_text(json.dumps(data, indent=2) + "\n")
PY

cat > /opt/mrh-admin/xray-info.json <<EOF
{"uuid":"$XRAY_UUID","path":"/","remark":"ghtun"}
EOF

if ! pgrep -f "$XRAY_PROCESS_PATTERN" >/dev/null; then
  sudo nohup /usr/local/bin/xray -c /tmp/config.runtime.json >/tmp/xray.log 2>&1 &
fi

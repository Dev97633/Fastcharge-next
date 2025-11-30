#!/bin/sh

MODID="fastcharge-next"
PERSIST="/data/adb/$MODID"
CFG_FILE="$PERSIST/config.prop"
LOG_FILE="$PERSIST/fastcharge.log"

mkdir -p "$PERSIST"

# Create default config if missing
if [ ! -f "$CFG_FILE" ]; then
  cat > "$CFG_FILE" <<'EOF'
ENABLE=1
TARGET_PATH=/sys/class/power_supply/battery/constant_charge_current_max
DEFAULT_CURRENT=500000
FAST_CURRENT=1000000
POLL_NORMAL=5
POLL_FAST=1
THERMAL_LIMIT=45000
LOG_MAX_KB=128
LOG_FILE=/data/adb/fastcharge-next/fastcharge.log
EOF
fi

# Init log
if [ ! -f "$LOG_FILE" ]; then
  : > "$LOG_FILE"
fi

chmod 600 "$LOG_FILE"
chmod 600 "$CFG_FILE"

# Log entry
ts=$(date +"%Y-%m-%d %H:%M:%S" 2>/dev/null || date)
echo "$ts post-fs-data: initialized" >> "$LOG_FILE" 2>/dev/null

exit 0

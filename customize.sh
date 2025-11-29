#!/bin/sh
set -u
MODID=fastcharge-next
MODDIR="$1"
CFG_DIR="/data/adb/modules/$MODID"
CFG_FILE="$CFG_DIR/config.prop"

ui_print() { echo "$1"; }

ui_print "Installing FastCharge Next..."

if [ ! -d "$CFG_DIR" ]; then
  mkdir -p "$CFG_DIR" || ui_print "[WARN] Could not create $CFG_DIR"
fi

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
LOG_FILE=/data/adb/modules/fastcharge-next/fastcharge.log
EOF
  ui_print "Seeded default config at $CFG_FILE"
else
  ui_print "Config already exists, leaving it."
fi

ui_print "Installation complete."

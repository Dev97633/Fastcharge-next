#!/bin/sh
set -u

MODID="fastcharge-next"
MODDIR="$MODPATH"
CFG_DIR="$MODDIR"
CFG_FILE="$CFG_DIR/config.prop"

ui_print() { echo "$1"; }

ui_print "Installing FastCharge Next..."

# Create module directory (it already exists, but safe)
mkdir -p "$CFG_DIR"

# Seed default config
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
  ui_print "Config already exists, skipping."
fi

ui_print "Installation complete."

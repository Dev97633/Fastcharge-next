#!/bin/sh

# Universal installer (Magisk + KernelSU + APatch)

MODID="fastcharge-next"
MODDIR="/data/adb/modules/$MODID"
CFG_FILE="$MODDIR/config.prop"

echo "Installing FastCharge Next..."


if [ ! -d "$MODDIR" ]; then
    mkdir -p "$MODDIR" || echo "[WARN] Failed to create $MODDIR"
fi

if [ ! -f "$CFG_FILE" ]; then
cat > "$CFG_FILE" <<'EOF'
ENABLE=1
TARGET_PATH=
DEFAULT_CURRENT=500000
FAST_CURRENT=1000000
POLL_NORMAL=5
POLL_FAST=1
THERMAL_LIMIT=45000
LOG_FILE=/data/adb/modules/fastcharge-next/fastcharge.log
LOG_MAX_KB=128
EOF

    echo "Default config created at: $CFG_FILE"
else
    echo "Config already exists — keeping user settings."
fi

echo "Installation complete."

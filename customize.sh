#!/system/bin/sh

##########################################################################################
# FastCharge Next - Customize Script
##########################################################################################

# Magisk UI print
ui_print() { echo "$1"; }

MODID="fastcharge-next"
MODDIR="/data/adb/modules/$MODID"
PERSIST="/data/adb/$MODID"
CFG_FILE="$PERSIST/config.prop"

ui_print "- Setting up FastCharge Next..."

# Ensure module directory exists
if [ ! -d "$MODDIR" ]; then
    mkdir -p "$MODDIR" 2>/dev/null
    ui_print "- Created module directory"
fi

# Create default config if not exists
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

    ui_print "- Default config created"
else
    ui_print "- Config already exists (preserved)"
fi

# Set proper permissions (important)
chmod 0644 "$CFG_FILE" 2>/dev/null

ui_print "- Installation setup complete"

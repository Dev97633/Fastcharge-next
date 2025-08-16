#!/system/bin/sh
# Magisk install-time script: seed default config

CFG_DIR="/sdcard/FastCharge"
CFG_FILE="\$CFG_DIR/config.prop"

mkdir -p "\$CFG_DIR" 2>/dev/null || true

if [ ! -f "\$CFG_FILE" ]; then
  cat > "\$CFG_FILE" <<'CFG'
# ===== FastCharge Next config =====
# Units:
#   *_MA   -> milliamps (mA)
#   *_UV   -> microvolts (uV)

# Target maximum charge current when cool (mA)
CURRENT_MAX_MA=2000

# Battery constant-charge current cap (mA). 0 = don't touch
CC_CURRENT_MAX_MA=0

# Battery constant-charge voltage max (uV). 0 = don't touch
CONSTANT_VOLTAGE_MAX_UV=0

# Temperature limits (°C)
TEMP_HOT_C=42
TEMP_COOL_C=39

# Logging
LOG_ENABLED=1
CFG
fi

ui_print "FastCharge Next: config seeded at \$CFG_FILE"

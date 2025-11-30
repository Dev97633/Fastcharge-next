#!/bin/sh

MODID="fastcharge-next"
PERSIST="/data/adb/$MODID"
CFG_FILE="$PERSIST/config.prop"

# Reset charging node if possible
if [ -f "$CFG_FILE" ]; then
  . "$CFG_FILE"

  # Only reset if path exists AND is writable
  if [ -n "$TARGET_PATH" ] && [ -w "$TARGET_PATH" ]; then
    echo "$DEFAULT_CURRENT" > "$TARGET_PATH" 2>/dev/null
  fi
fi

# Remove persistent storage (config, logs)
rm -rf "$PERSIST" 2>/dev/null

# Do NOT delete $MODPATH or /data/adb/modules/…
# Magisk/KernelSU will remove module folder itself.
exit 0

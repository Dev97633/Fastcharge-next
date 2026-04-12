#!/system/bin/sh

MODID="fastcharge-next"
MODDIR="/data/adb/modules/$MODID"
PERSIST="/data/adb/$MODID"
CFG_FILE="$PERSIST/config.prop"

ui_print() { echo "$1"; }

ui_print "- Uninstalling FastCharge Next..."

if [ -f "$CFG_FILE" ]; then
  . "$CFG_FILE"

  if [ -n "$TARGET_PATH" ] && [ -w "$TARGET_PATH" ]; then
    printf "%s" "${DEFAULT_CURRENT:-0}" > "$TARGET_PATH" 2>/dev/null
    ui_print "- Restored default charging current"
  else
    ui_print "- Skipped restore (invalid target)"
  fi
fi

rm -rf "$PERSIST" 2>/dev/null

ui_print "- Cleanup complete"

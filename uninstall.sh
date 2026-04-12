#!/bin/sh

rm -rf /data/adb/$MODID
CFG_FILE="$MODDIR/config.prop"

if [ -f "$CFG_FILE" ]; then
  . "$CFG_FILE"
  [ -w "$TARGET_PATH" ] && printf "%s" "$DEFAULT_CURRENT" > "$TARGET_PATH"
fi

rm -rf "$MODDIR"

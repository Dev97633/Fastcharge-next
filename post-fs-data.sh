#!/bin/sh

MODID=fastcharge-next
MODDIR="/data/adb/modules/$MODID"
LOG_FILE="$MODDIR/fastcharge.log"

log() {
  ts=$(date +"%Y-%m-%d %H:%M:%S" 2>/dev/null || date)
  printf "%s %s\n" "$ts" "$1" >> "$LOG_FILE" 2>/dev/null || true
}

mkdir -p "$MODDIR" 2>/dev/null || true

if [ ! -f "$LOG_FILE" ]; then
  : > "$LOG_FILE"
  chmod 600 "$LOG_FILE"
fi

log "post-fs-data: initialized"

exit 0

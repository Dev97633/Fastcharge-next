#!/bin/sh

MODDIR="/data/adb/modules/fastcharge-next"
LOG_FILE="$MODDIR/fastcharge.log"

# Create module directory if missing
mkdir -p "$MODDIR" 2>/dev/null

# Create log file if missing
if [ ! -f "$LOG_FILE" ]; then
    : > "$LOG_FILE"
    chmod 600 "$LOG_FILE"
fi

# Log startup
ts=$(date +"%Y-%m-%d %H:%M:%S")
printf "%s %s\n" "$ts" "post-fs-data: initialized" >> "$LOG_FILE"

exit 0

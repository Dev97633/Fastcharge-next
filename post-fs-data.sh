#!/system/bin/sh

MODID="fastcharge-next"
PERSIST="/data/adb/$MODID"
MODDIR="$PERSIST"
LOG_FILE="$MODDIR/fastcharge.log"


mkdir -p "$MODDIR" 2>/dev/null
chmod 755 "$MODDIR" 2>/dev/null


if [ ! -f "$LOG_FILE" ]; then
    : > "$LOG_FILE"
    chmod 600 "$LOG_FILE"
fi


ts=$(date +"%Y-%m-%d %H:%M:%S" 2>/dev/null)
printf "%s %s\n" "$ts" "post-fs-data: initialized" >> "$LOG_FILE" 2>/dev/null

exit 0

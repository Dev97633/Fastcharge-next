#!/system/bin/sh
set -eu
MODDIR="${0%/*}"
LOG="$MODDIR/log.txt"
touch "$LOG" 2>/dev/null || true
chmod 0644 "$LOG" 2>/dev/null || true

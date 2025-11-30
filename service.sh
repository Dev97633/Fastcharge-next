#!/bin/sh

MODDIR="/data/adb/modules/fastcharge-next"
CFG_FILE="$MODDIR/config.prop"
LOG_FILE="$MODDIR/fastcharge.log"

ENABLE=0
TARGET_PATH=""
DEFAULT_CURRENT=500000
FAST_CURRENT=1000000
POLL_NORMAL=5
POLL_FAST=1
THERMAL_LIMIT=45000

log() {
  ts=$(date +"%Y-%m-%d %H:%M:%S")
  printf "%s %s\n" "$ts" "$1" >> "$LOG_FILE"
}

load_config() {
  [ -f "$CFG_FILE" ] && . "$CFG_FILE"
}

safe_write() {
  [ -w "$1" ] && printf "%s" "$2" > "$1"
}

is_charging() {
  for p in /sys/class/power_supply/*/status; do
    [ -r "$p" ] || continue
    st=$(cat "$p")
    case "$st" in
      "Charging"|"Full") return 0 ;;
    esac
  done
  return 1
}

load_config
log "service: starting"

if [ -z "$TARGET_PATH" ]; then
  for f in /sys/class/power_supply/*/constant_charge_current_max \
           /sys/class/power_supply/*/current_max; do
    [ -w "$f" ] && TARGET_PATH="$f" && break
  done
fi

if [ ! -w "$TARGET_PATH" ]; then
  log "No writable charge current node found. Exiting."
  exit 0
fi

prev_mode="normal"

while true; do
  load_config

  if [ "$ENABLE" != "1" ]; then
    safe_write "$TARGET_PATH" "$DEFAULT_CURRENT"
    sleep 60
    continue
  fi

  temp_ok=1
  for t in /sys/class/thermal/thermal_zone*/temp; do
    [ -r "$t" ] || continue
    tmp=$(cat "$t" | tr -cd '0-9')
    [ "$tmp" != "" ] && [ "$tmp" -ge "$THERMAL_LIMIT" ] && temp_ok=0
  done

  if is_charging; then
    if [ "$temp_ok" -eq 1 ]; then
      safe_write "$TARGET_PATH" "$FAST_CURRENT"
      mode="fast"
    else
      safe_write "$TARGET_PATH" "$DEFAULT_CURRENT"
      mode="normal"
    fi
  else
    safe_write "$TARGET_PATH" "$DEFAULT_CURRENT"
    mode="normal"
  fi

  interval=$([ "$mode" = "fast" ] && echo "$POLL_FAST" || echo "$POLL_NORMAL")

  if [ "$mode" != "$prev_mode" ]; then
    log "Mode: $prev_mode -> $mode"
    prev_mode="$mode"
  fi

  sleep "$interval"
done

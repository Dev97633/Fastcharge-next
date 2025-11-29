#!/bin/sh

MODID=fastcharge-next
MODDIR="/data/adb/modules/$MODID"
CFG_FILE="$MODDIR/config.prop"
LOG_FILE="$MODDIR/fastcharge.log"

ENABLE=0
TARGET_PATH=""
DEFAULT_CURRENT=0
FAST_CURRENT=0
POLL_NORMAL=5
POLL_FAST=1
THERMAL_LIMIT=45000

log() {
  ts=$(date +"%Y-%m-%d %H:%M:%S" 2>/dev/null || date)
  printf "%s %s\n" "$ts" "$1" >> "$LOG_FILE" 2>/dev/null || true
}

load_config() {
  [ -f "$CFG_FILE" ] && . "$CFG_FILE"
}

safe_write() {
  [ -w "$1" ] && printf "%s" "$2" > "$1" 2>/dev/null
}

is_charging() {
  for p in /sys/class/power_supply/*/status; do
    [ -r "$p" ] || continue
    st=$(cat "$p")
    [ "$st" = "Charging" ] && return 0
    [ "$st" = "Full" ] && return 0
  done
  return 1
}

load_config
log "service: starting"

if [ -z "$TARGET_PATH" ]; then
  for f in /sys/class/power_supply/*/constant_charge_current_max /sys/class/power_supply/*/current_max; do
    [ -w "$f" ] && TARGET_PATH="$f" && break
  done
fi

if [ ! -w "$TARGET_PATH" ]; then
  log "service: no valid writable target found, exiting"
  exit 0
fi

prev_mode="normal"
interval="$POLL_NORMAL"

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

  if [ "$mode" = "fast" ]; then interval="$POLL_FAST"; else interval="$POLL_NORMAL"; fi

  if [ "$mode" != "$prev_mode" ]; then
    log "Mode: $prev_mode -> $mode"
    prev_mode="$mode"
  fi

  sleep "$interval"
done

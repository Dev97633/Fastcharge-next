#!/bin/sh

MODID="fastcharge-next"
PERSIST_DIR="/data/adb/$MODID"
CFG_FILE="$PERSIST_DIR/config.prop"
LOG_FILE="$PERSIST_DIR/fastcharge.log"

mkdir -p "$PERSIST_DIR"

ENABLE=0
TARGET_PATH=""
DEFAULT_CURRENT=0
FAST_CURRENT=0
POLL_NORMAL=5
POLL_FAST=1
THERMAL_LIMIT=45000

log() {
  ts=$(date +"%Y-%m-%d %H:%M:%S")
  echo "$ts $1" >> "$LOG_FILE" 2>/dev/null || true
}

load_config() {
  [ -f "$CFG_FILE" ] && . "$CFG_FILE"
}

safe_write() {
  echo "$2" > "$1" 2>/dev/null
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

# Better auto-detection
for f in \
  /sys/class/power_supply/*/constant_charge_current_max \
  /sys/class/power_supply/*/current_max \
  /sys/class/power_supply/*/charge_current \
  /sys/class/power_supply/*/input_current_max \
  /sys/class/power_supply/*/fcc* \
  /sys/class/power_supply/battery/charge_control_limit_max;
do
  [ -w "$f" ] && TARGET_PATH="$f" && break
done

if [ ! -w "$TARGET_PATH" ]; then
  log "no writable charging node found"
  exit 0
fi

log "using node: $TARGET_PATH"

prev_mode="normal"
interval="$POLL_NORMAL"

while true; do
  load_config

  if [ "$ENABLE" != "1" ]; then
    safe_write "$TARGET_PATH" "$DEFAULT_CURRENT"
    sleep 60
    continue
  fi

  # Thermal check (skip invalid zones)
  temp_ok=1
  for t in /sys/class/thermal/thermal_zone*/temp; do
    [ -r "$t" ] || continue
    tmp=$(cat "$t" 2>/dev/null)
    case "$tmp" in
      ''|*[!0-9]*) continue ;; # skip non-numeric
    esac
    [ "$tmp" -ge "$THERMAL_LIMIT" ] && temp_ok=0
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

  [ "$mode" = "fast" ] && interval="$POLL_FAST" || interval="$POLL_NORMAL"

  if [ "$mode" != "$prev_mode" ]; then
    log "Mode: $prev_mode -> $mode"
    prev_mode="$mode"
  fi

  sleep "$interval"
done

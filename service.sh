#!/system/bin/sh
# FastCharge Next – boot service
set -eu

MODDIR="${0%/*}"
LOG="$MODDIR/log.txt"
CFG="/sdcard/FastCharge/config.prop"

log() {
  [ "${LOG_ENABLED:-1}" = "1" ] && echo "$(date '+%F %T') | $*" >> "$LOG"
}

# Load config (with defaults)
CURRENT_MAX_MA=2000
CC_CURRENT_MAX_MA=0
CONSTANT_VOLTAGE_MAX_UV=0
TEMP_HOT_C=42
TEMP_COOL_C=39
LOG_ENABLED=1

[ -f "$CFG" ] && . "$CFG" || true

to_uA() { # mA -> uA
  awk "BEGIN{printf \"%d\", $1*1000}"
}

# Find candidate sysfs nodes
PS_BASE="/sys/class/power_supply"
CAND_USB="$PS_BASE/usb $PS_BASE/charger $PS_BASE/dc $PS_BASE/ac"
BAT="$PS_BASE/battery"

first_writable() {
  for f in $1; do
    if [ -e "$f" ] && [ -w "$f" ]; then
      echo "$f"; return 0
    fi
  done
  return 1
}

USB_CURRENT_NODES=""
for p in $CAND_USB; do
  [ -d "$p" ] || continue
  for n in current_max input_current_limit; do
    USB_CURRENT_NODES="$USB_CURRENT_NODES $p/$n"
  done
done

BAT_CURRENT_NODES="$BAT/constant_charge_current_max $BAT/charge_current_max"
BAT_VOLT_NODE="$BAT/constant_charge_voltage_max"
TEMP_NODE="$BAT/temp"

USB_NODE="$(first_writable "$USB_CURRENT_NODES" || true)"
BAT_CUR_NODE="$(first_writable "$BAT_CURRENT_NODES" || true)"
BAT_VOLT_NODE_WRITABLE="$(first_writable "$BAT_VOLT_NODE" || true)"

log "Detected nodes: USB=$USB_NODE BAT_CUR=$BAT_CUR_NODE BAT_VOLT=$BAT_VOLT_NODE_WRITABLE TEMP=$TEMP_NODE"

TARGET_USB_UA="$(to_uA "$CURRENT_MAX_MA")"
TARGET_BAT_UA="$(to_uA "${CC_CURRENT_MAX_MA:-0}")"

apply_targets() {
  local why="${1:-apply}"
  if [ -n "${USB_NODE:-}" ] && [ "${CURRENT_MAX_MA:-0}" -gt 0 ]; then
    echo "$TARGET_USB_UA" > "$USB_NODE" 2>/dev/null || log "WARN: write USB current failed"
    log "$why: set USB current_max to ${CURRENT_MAX_MA}mA"
  fi
  if [ -n "${BAT_CUR_NODE:-}" ] && [ "${CC_CURRENT_MAX_MA:-0}" -gt 0 ]; then
    echo "$TARGET_BAT_UA" > "$BAT_CUR_NODE" 2>/dev/null || log "WARN: write BAT current failed"
    log "$why: set BAT constant_charge_current_max to ${CC_CURRENT_MAX_MA}mA"
  fi
  if [ -n "${BAT_VOLT_NODE_WRITABLE:-}" ] && [ "${CONSTANT_VOLTAGE_MAX_UV:-0}" -gt 0 ]; then
    echo "$CONSTANT_VOLTAGE_MAX_UV" > "$BAT_VOLT_NODE_WRITABLE" 2>/dev/null || log "WARN: write BAT voltage failed"
    log "$why: set BAT constant_charge_voltage_max to ${CONSTANT_VOLTAGE_MAX_UV}uV"
  fi
}

clamp() {
  awk -v v="$1" -v lo="$2" -v hi="$3" 'BEGIN{ if(v<lo) v=lo; if(v>hi) v=hi; printf "%d", v }'
}

CURRENT_MAX_MA="$(clamp "${CURRENT_MAX_MA:-0}" 500 3000)"
CC_CURRENT_MAX_MA="$(clamp "${CC_CURRENT_MAX_MA:-0}" 0 3000)"
CONSTANT_VOLTAGE_MAX_UV="$(clamp "${CONSTANT_VOLTAGE_MAX_UV:-0}" 0 4600000)"
TEMP_HOT_C="$(clamp "${TEMP_HOT_C:-42}" 35 48)"
TEMP_COOL_C="$(clamp "${TEMP_COOL_C:-39}" 30 47)"

log "Config: USB=${CURRENT_MAX_MA}mA BAT=${CC_CURRENT_MAX_MA}mA VOLT=${CONSTANT_VOLTAGE_MAX_UV}uV HOT=${TEMP_HOT_C}C COOL=${TEMP_COOL_C}C"

apply_targets "initial"

prev_state="normal"
while :; do
  sleep 20
  [ -e "$TEMP_NODE" ] || continue
  raw="$(cat "$TEMP_NODE" 2>/dev/null || echo 0)"
  temp_c="$(awk "BEGIN{printf \"%.1f\", $raw/10}")"

  if awk "BEGIN{exit !($temp_c >= $TEMP_HOT_C)}"; then
    backoff_mA=1000
    if [ "$prev_state" != "hot" ]; then
      if [ -n "${USB_NODE:-}" ]; then
        echo "$(to_uA $backoff_mA)" > "$USB_NODE" 2>/dev/null || true
      fi
      if [ -n "${BAT_CUR_NODE:-}" ] && [ "${CC_CURRENT_MAX_MA:-0}" -gt 0 ]; then
        echo "$(to_uA $backoff_mA)" > "$BAT_CUR_NODE" 2>/dev/null || true
      fi
      log "thermal: $temp_c C >= ${TEMP_HOT_C}C -> backoff to ${backoff_mA}mA"
      prev_state="hot"
    fi
  elif awk "BEGIN{exit !($temp_c <= $TEMP_COOL_C)}"; then
    if [ "$prev_state" = "hot" ]; then
      apply_targets "restore"
      log "thermal: $temp_c C <= ${TEMP_COOL_C}C -> restored targets"
      prev_state="normal"
    fi
  fi
done

#!/system/bin/sh
#
# service.sh - FastCharge Next

MODID="fastcharge-next"
PERSIST="/data/adb/$MODID"
CFG_FILE="$PERSIST/config.prop"
LOG_FILE="$PERSIST/fastcharge.log"

ENABLE=1
TARGET_PATH=""
DEFAULT_CURRENT=500000      # microamps (µA) (example)
FAST_CURRENT=1000000
POLL_NORMAL=30              # seconds (normal polling interval)
POLL_FAST=1                 # seconds (fast-charge polling interval)
THERMAL_LIMIT=45000         # millidegC (45000 => 45.0°C)
LOG_MAX_KB=128              # rotate when log > 128 KB
INVALID_RETRY=60            # seconds to wait when TARGET_PATH invalid
EXTENDED_DETECT=true        # try more candidate names if basic detect fails

mkdir -p "$PERSIST" 2>/dev/null || true

log() {
  ts=$(date +"%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$(date)")
  printf "%s %s\n" "$ts" "$1" >> "$LOG_FILE" 2>/dev/null || true

  if [ -n "$LOG_MAX_KB" ]; then
    size_bytes=$(wc -c < "$LOG_FILE" 2>/dev/null || echo 0)
    size_kb=$(( (size_bytes + 1023) / 1024 ))
    if [ "$size_kb" -gt "$LOG_MAX_KB" ]; then
      tail -c 102400 "$LOG_FILE" > "${LOG_FILE}.tmp" 2>/dev/null || true
      mv "${LOG_FILE}.tmp" "$LOG_FILE" 2>/dev/null || true
    fi
  fi
}

load_config() {
  if [ -f "$CFG_FILE" ]; then
    # shellcheck disable=SC1090
    . "$CFG_FILE" 2>/dev/null || true
  fi

  DEFAULT_CURRENT=${DEFAULT_CURRENT:-500000}
  FAST_CURRENT=${FAST_CURRENT:-1000000}
  POLL_NORMAL=${POLL_NORMAL:-30}
  POLL_FAST=${POLL_FAST:-1}
  THERMAL_LIMIT=${THERMAL_LIMIT:-45000}
  LOG_MAX_KB=${LOG_MAX_KB:-128}
  INVALID_RETRY=${INVALID_RETRY:-60}
}

sanitize_digits() {
  echo "$1" | tr -cd '0-9' || echo ""
}

safe_write() {
  path="$1"
  val="$2"
  if [ -z "$path" ]; then
    return 1
  fi
  printf "%s" "$val" > "$path" 2>/dev/null && return 0
  sh -c "printf '%s' '$val' > '$path'" 2>/dev/null && return 0
  return 1
}

is_charging() {
  for status in /sys/class/power_supply/*/status; do
    [ -r "$status" ] || continue
    st=$(cat "$status" 2>/dev/null || echo "")
    case "$st" in
      "Charging"|"Full"|"charging"|"FULL"|"CHARGING")
        return 0
        ;;
    esac
  done
  return 1
}

thermal_ok() {
  # thermal files may be in millidegree or degree; we assume millidegree
  for t in /sys/class/thermal/thermal_zone*/temp; do
    [ -r "$t" ] || continue
    tmp=$(cat "$t" 2>/dev/null || echo "")
    # leave only digits
    tmp=$(sanitize_digits "$tmp")
    [ -z "$tmp" ] && continue
    # if tmp seems small (<1000), assume degrees Celsius -> convert
    if [ "$tmp" -lt 1000 ]; then
      tmp=$((tmp * 1000))
    fi
    if [ "$tmp" -ge "$THERMAL_LIMIT" ]; then
      return 1
    fi
  done
  return 0
}

detect_candidates() {
  # basic candidates
  echo /sys/class/power_supply/*/constant_charge_current_max
  echo /sys/class/power_supply/*/current_max
  echo /sys/class/power_supply/*/charge_current
  echo /sys/class/power_supply/*/input_current_max
  echo /sys/class/power_supply/*/fcc
  echo /sys/class/power_supply/*/charging_current
  # extended vendor nodes
  echo /sys/class/power_supply/*/force_charge_current
  echo /sys/class/power_supply/battery/charge_control_limit_max
  echo /sys/class/power_supply/*/safety_current_max
  echo /sys/class/power_supply/*/limit_current
  echo /sys/class/power_supply/*/current_now
}

detect_target() {
  TARGET_PATH=""
  # iterate candidates; expand globs manually
  for pattern in $(detect_candidates); do
    for f in $pattern; do
      [ -e "$f" ] || continue
      # some nodes are files but not writable; prefer writable ones
      if [ -w "$f" ]; then
        TARGET_PATH="$f"
        return 0
      fi
    done
  done
  return 1
}

load_config
log "service: starting (pid $$)"

if [ -n "${TARGET_PATH:-}" ]; then
  if [ ! -w "$TARGET_PATH" ]; then
    log "Configured TARGET_PATH '$TARGET_PATH' is not writable. It will be ignored and auto-detected."
    TARGET_PATH=""
  fi
fi

if [ -z "${TARGET_PATH:-}" ]; then
  if detect_target; then
    log "Auto-detected target: $TARGET_PATH"
  else
    log "No writable charging node auto-detected (will retry)."
  fi
fi

logged_invalid=0

prev_mode="unknown"
while true; do
  load_config

  DEFAULT_CURRENT=$(sanitize_digits "${DEFAULT_CURRENT:-500000}")
  FAST_CURRENT=$(sanitize_digits "${FAST_CURRENT:-1000000}")
  POLL_NORMAL=$(sanitize_digits "${POLL_NORMAL:-30}")
  POLL_FAST=$(sanitize_digits "${POLL_FAST:-1}")
  THERMAL_LIMIT=$(sanitize_digits "${THERMAL_LIMIT:-45000}")
  LOG_MAX_KB=$(sanitize_digits "${LOG_MAX_KB:-128}")

  if [ -z "${TARGET_PATH:-}" ] || [ ! -w "$TARGET_PATH" ]; then
    if [ "$logged_invalid" -eq 0 ]; then
      log "TARGET_PATH invalid or missing - will retry every ${INVALID_RETRY}s"
      logged_invalid=1
    fi

    if detect_target; then
      log "Auto-detect succeeded: $TARGET_PATH"
      logged_invalid=0
      continue
    fi

    sleep "${INVALID_RETRY}"
    continue
  fi

  logged_invalid=0

  if [ "${ENABLE:-1}" != "1" ]; then
    safe_write "$TARGET_PATH" "${DEFAULT_CURRENT:-0}"
    # sleep a bit longer when disabled
    sleep "${POLL_NORMAL:-30}"
    continue
  fi

  if thermal_ok; then
    thermal_state_ok=1
  else
    thermal_state_ok=0
  fi

  if is_charging; then
    charging=1
  else
    charging=0
  fi

  if [ "$charging" -eq 1 ] && [ "$thermal_state_ok" -eq 1 ] && [ -n "${FAST_CURRENT:-}" ] && [ "${FAST_CURRENT:-0}" -ne 0 ]; then
    # try to apply fast current
    if safe_write "$TARGET_PATH" "${FAST_CURRENT}"; then
      mode="fast"
    else
      mode="normal"
      safe_write "$TARGET_PATH" "${DEFAULT_CURRENT}"
    fi
  else
    safe_write "$TARGET_PATH" "${DEFAULT_CURRENT}"
    mode="normal"
  fi

  if [ "$mode" != "$prev_mode" ]; then
    log "Mode change: $prev_mode -> $mode (charging=$charging thermal_ok=$thermal_state_ok target=$TARGET_PATH)"
    prev_mode="$mode"
  fi

  if [ "$mode" = "fast" ]; then
    sleep "${POLL_FAST:-1}"
  else
    sleep "${POLL_NORMAL:-30}"
  fi
done




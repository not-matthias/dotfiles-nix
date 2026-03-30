#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_RUNTIME_DIR:-/run/user/$UID}/ultra-power-saver"
STATE_FILE="$STATE_DIR/state"
CPU_STATE_FILE="$STATE_DIR/cpu-state"
SYSTEM_STATE_FILE="$STATE_DIR/system-units"
BLUETOOTH_STATE_FILE="$STATE_DIR/bluetooth-state"

ULTRA_MAX_FREQ_KHZ="${ULTRA_MAX_FREQ_KHZ:-900000}"

SYSTEM_UNITS=(
  tailscaled.service
  opensnitchd.service
  mullvad-daemon.service
  navidrome.service
  restic-backups-local.timer
  restic-backups-remote.timer
)

mkdir -p "$STATE_DIR"

log() {
  printf '%s\n' "$*"
}

require_sudo() {
  sudo -v
}

set_state() {
  printf '%s\n' "$1" > "$STATE_FILE"
}

get_state() {
  if [[ -f "$STATE_FILE" ]]; then
    cat "$STATE_FILE"
    return
  fi

  printf 'off\n'
}

system_unit_exists() {
  systemctl list-unit-files "$1" --no-legend 2>/dev/null | grep -q .
}

record_system_unit_states() {
  : > "$SYSTEM_STATE_FILE"

  for unit in "${SYSTEM_UNITS[@]}"; do
    if ! system_unit_exists "$unit"; then
      continue
    fi

    if systemctl is-active --quiet "$unit"; then
      printf '%s=active\n' "$unit" >> "$SYSTEM_STATE_FILE"
      continue
    fi

    printf '%s=inactive\n' "$unit" >> "$SYSTEM_STATE_FILE"
  done
}

stop_system_units() {
  for unit in "${SYSTEM_UNITS[@]}"; do
    if ! system_unit_exists "$unit"; then
      continue
    fi

    sudo systemctl stop "$unit"
  done
}

start_system_units() {
  if [[ ! -f "$SYSTEM_STATE_FILE" ]]; then
    return
  fi

  while IFS='=' read -r unit state; do
    if [[ "$state" != "active" ]]; then
      continue
    fi

    sudo systemctl start "$unit"
  done < "$SYSTEM_STATE_FILE"
}

save_cpu_state() {
  : > "$CPU_STATE_FILE"

  if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq ]]; then
    printf 'scaling_max_freq=%s\n' "$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq)" >> "$CPU_STATE_FILE"
  fi

  if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference ]]; then
    printf 'energy_performance_preference=%s\n' "$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference)" >> "$CPU_STATE_FILE"
  fi

  if [[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]]; then
    printf 'intel_no_turbo=%s\n' "$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)" >> "$CPU_STATE_FILE"
  fi

  if [[ -f /sys/devices/system/cpu/cpufreq/boost ]]; then
    printf 'boost=%s\n' "$(cat /sys/devices/system/cpu/cpufreq/boost)" >> "$CPU_STATE_FILE"
  fi
}

read_saved_value() {
  local key="$1"

  if [[ ! -f "$CPU_STATE_FILE" ]]; then
    return
  fi

  awk -F '=' -v key="$key" '$1 == key { print $2 }' "$CPU_STATE_FILE" | tail -n 1
}

apply_cpu_limits() {
  sudo auto-cpufreq --force powersave

  if compgen -G '/sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq' >/dev/null; then
    for path in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
      printf '%s\n' "$ULTRA_MAX_FREQ_KHZ" | sudo tee "$path" >/dev/null
    done
  fi

  if compgen -G '/sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference' >/dev/null; then
    for path in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
      printf 'power\n' | sudo tee "$path" >/dev/null
    done
  fi

  if [[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]]; then
    printf '1\n' | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo >/dev/null
  fi

  if [[ -f /sys/devices/system/cpu/cpufreq/boost ]]; then
    printf '0\n' | sudo tee /sys/devices/system/cpu/cpufreq/boost >/dev/null
  fi
}

restore_cpu_limits() {
  local scaling_max_freq
  local energy_performance_preference
  local intel_no_turbo
  local boost

  sudo auto-cpufreq --force reset

  scaling_max_freq="$(read_saved_value scaling_max_freq || true)"
  if [[ -n "$scaling_max_freq" ]] && compgen -G '/sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq' >/dev/null; then
    for path in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
      printf '%s\n' "$scaling_max_freq" | sudo tee "$path" >/dev/null
    done
  fi

  energy_performance_preference="$(read_saved_value energy_performance_preference || true)"
  if [[ -n "$energy_performance_preference" ]] && compgen -G '/sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference' >/dev/null; then
    for path in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
      printf '%s\n' "$energy_performance_preference" | sudo tee "$path" >/dev/null
    done
  fi

  intel_no_turbo="$(read_saved_value intel_no_turbo || true)"
  if [[ -n "$intel_no_turbo" ]] && [[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]]; then
    printf '%s\n' "$intel_no_turbo" | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo >/dev/null
  fi

  boost="$(read_saved_value boost || true)"
  if [[ -n "$boost" ]] && [[ -f /sys/devices/system/cpu/cpufreq/boost ]]; then
    printf '%s\n' "$boost" | sudo tee /sys/devices/system/cpu/cpufreq/boost >/dev/null
  fi
}

save_bluetooth_state() {
  : > "$BLUETOOTH_STATE_FILE"

  if ! command -v bluetoothctl >/dev/null 2>&1; then
    return
  fi

  if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    printf 'powered=yes\n' >> "$BLUETOOTH_STATE_FILE"
    return
  fi

  printf 'powered=no\n' >> "$BLUETOOTH_STATE_FILE"
}

disable_bluetooth() {
  if ! command -v bluetoothctl >/dev/null 2>&1; then
    return
  fi

  bluetoothctl power off >/dev/null 2>&1 || true
  sudo systemctl stop bluetooth.service >/dev/null 2>&1 || true
}

restore_bluetooth() {
  if [[ ! -f "$BLUETOOTH_STATE_FILE" ]]; then
    return
  fi

  if ! command -v bluetoothctl >/dev/null 2>&1; then
    return
  fi

  if grep -q '^powered=yes$' "$BLUETOOTH_STATE_FILE"; then
    sudo systemctl start bluetooth.service >/dev/null 2>&1 || true
    bluetoothctl power on >/dev/null 2>&1 || true
  fi
}

print_unit_status() {
  for unit in "${SYSTEM_UNITS[@]}"; do
    if ! system_unit_exists "$unit"; then
      continue
    fi

    if systemctl is-active --quiet "$unit"; then
      printf '  - %s: active\n' "$unit"
      continue
    fi

    printf '  - %s: inactive\n' "$unit"
  done
}

print_cpu_status() {
  local governor="unknown"
  local scaling_max_freq="unknown"
  local epp="n/a"
  local turbo="n/a"

  if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]]; then
    governor="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
  fi

  if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq ]]; then
    scaling_max_freq="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq)"
  fi

  if [[ -f /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference ]]; then
    epp="$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference)"
  fi

  if [[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]]; then
    turbo="intel no_turbo=$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)"
  elif [[ -f /sys/devices/system/cpu/cpufreq/boost ]]; then
    turbo="boost=$(cat /sys/devices/system/cpu/cpufreq/boost)"
  fi

  printf 'CPU:\n'
  printf '  - governor: %s\n' "$governor"
  printf '  - scaling_max_freq: %s\n' "$scaling_max_freq"
  printf '  - epp: %s\n' "$epp"
  printf '  - turbo: %s\n' "$turbo"
}

print_bluetooth_status() {
  if ! command -v bluetoothctl >/dev/null 2>&1; then
    printf 'Bluetooth:\n'
    printf '  - unavailable\n'
    return
  fi

  printf 'Bluetooth:\n'
  if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    printf '  - powered on\n'
    return
  fi

  printf '  - powered off\n'
}

cmd_on() {
  require_sudo

  if [[ "$(get_state)" == "on" ]]; then
    log 'Ultra power saver is already on.'
    return
  fi

  record_system_unit_states
  save_cpu_state
  save_bluetooth_state

  stop_system_units
  disable_bluetooth
  apply_cpu_limits
  set_state on

  log 'Ultra power saver enabled.'
}

cmd_off() {
  require_sudo

  if [[ "$(get_state)" == "off" ]]; then
    log 'Ultra power saver is already off.'
    return
  fi

  start_system_units
  restore_bluetooth
  restore_cpu_limits
  set_state off

  log 'Ultra power saver disabled.'
}

cmd_status() {
  printf 'State: %s\n' "$(get_state)"
  print_cpu_status
  print_bluetooth_status
  printf 'System units:\n'
  print_unit_status
}

main() {
  case "${1:-}" in
    on)
      cmd_on
      ;;
    off)
      cmd_off
      ;;
    status)
      cmd_status
      ;;
    *)
      printf 'Usage: ups <on|off|status>\n' >&2
      exit 1
      ;;
  esac
}

main "$@"

#!/usr/bin/env bash
# Amp usage for waybar — parses `amp usage` CLI output

# shellcheck disable=SC1090,SC1091
source "${AI_USAGE_COMMON:?AI_USAGE_COMMON not set}"

AMP_BIN="${AMP_BIN:?AMP_BIN not set}"

if ! command -v "$AMP_BIN" &>/dev/null; then
  output_error "Λ" "amp not found"
  exit 0
fi

force_refresh=0
if [ "${1:-}" = "--force-refresh" ]; then
  force_refresh=1
elif [ "${1:-}" = "--restart" ]; then
  clear_usage_cache "amp"
  force_refresh=1
fi

fetch_data() {
  local output
  output=$("$AMP_BIN" usage 2>&1)
  local rc=$?
  if [ "$rc" -ne 0 ]; then
    # shellcheck disable=SC2034
    LAST_HTTP_CODE="500"
    return 1
  fi
  echo "$output"
}

raw=$(get_cached_or_fetch "amp" 300 "$force_refresh")
rc=$?
if [ "$rc" -eq 2 ] || [ "$rc" -eq 1 ]; then
  output_error "Λ" "amp usage failed"
  exit 0
fi

# Parse: "Amp Free: $20/$20 remaining (replenishes +$0.83/hour) [+100% bonus for 20 more days]"
free_line=$(echo "$raw" | grep -i "^Amp Free:")

remaining=0
total=0
replenish_rate=""
bonus_info=""

if [ -n "$free_line" ]; then
  # Extract "$remaining/$total remaining" — first match of $X/$Y pattern
  remaining=$(echo "$free_line" | grep -oP ': \$\K[0-9.]+(?=/\$)')
  total=$(echo "$free_line" | grep -oP ': \$[0-9.]+/\$\K[0-9.]+(?= remaining)')
  replenish_rate=$(echo "$free_line" | grep -oP 'replenishes \+\$\K[0-9.]+/hour' || true)
  bonus_info=$(echo "$free_line" | grep -oP '\[\+[^\]]+\]' || true)
fi

individual_credits=""
credits_line=$(echo "$raw" | grep -i "^Individual credits:")
if [ -n "$credits_line" ]; then
  individual_credits=$(echo "$credits_line" | grep -oP ': \$\K[0-9.]+')
fi

# Calculate usage percentage (inverted: remaining/total = how much is USED)
used_pct=0
if [ -n "$total" ] && [ -n "$remaining" ] && [ "$(echo "$total > 0" | bc -l)" -eq 1 ]; then
  used_pct=$(echo "scale=0; (1 - $remaining / $total) * 100" | bc -l)
  if [ "$used_pct" -lt 0 ]; then used_pct=0; fi
  if [ "$used_pct" -gt 100 ]; then used_pct=100; fi
fi

cls=$(css_class "$used_pct")

tooltip="Amp Usage\n━━━━━━━━━━━━━━━━━━━━━━━━\nFree: \$${remaining}/\$${total} remaining"
if [ -n "$replenish_rate" ]; then
  tooltip="$tooltip\nReplenish: +\$${replenish_rate}"
fi
if [ -n "$bonus_info" ]; then
  tooltip="$tooltip\nBonus: ${bonus_info}"
fi
if [ -n "$individual_credits" ]; then
  tooltip="$tooltip\nPaid credits: \$${individual_credits}"
fi

printf '{"text":"Λ %s%%","tooltip":"%s","class":"%s","percentage":%s}\n' \
  "$used_pct" "$tooltip" "$cls" "$used_pct"

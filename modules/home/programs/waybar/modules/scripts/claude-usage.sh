#!/usr/bin/env bash
# Claude Code usage for waybar — reads OAuth token from ~/.claude/.credentials.json

# shellcheck disable=SC1090,SC1091
source "${AI_USAGE_COMMON:?AI_USAGE_COMMON not set}"

CREDENTIALS="$HOME/.claude/.credentials.json"
if [ ! -f "$CREDENTIALS" ]; then
  output_error "󰜡" "No credentials file"
  exit 0
fi

force_refresh=0
if [ "${1:-}" = "--force-refresh" ]; then
  force_refresh=1
elif [ "${1:-}" = "--restart" ]; then
  clear_usage_cache "claude"
  force_refresh=1
fi

fetch_data() {
  local token response http_code
  token=$(jq -r '.claudeAiOauth.accessToken' "$CREDENTIALS")
  response=$(curl -s -w '\n%{http_code}' "https://api.anthropic.com/api/oauth/usage" \
    -H "Authorization: Bearer $token" \
    -H "anthropic-beta: oauth-2025-04-20")
  http_code=$(echo "$response" | tail -1)
  # shellcheck disable=SC2034
  LAST_HTTP_CODE="$http_code"
  local body
  body=$(echo "$response" | sed '$d')
  if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
    echo "$body"
    return 0
  fi
  return 1
}

rate_limited=0
data=$(get_cached_or_fetch "claude" 300 "$force_refresh")
rc=$?
if [ "$rc" -eq 3 ]; then
  rate_limited=1
elif [ "$rc" -eq 2 ]; then
  output_error "󰜡" "Rate limited (no cache)"
  exit 0
elif [ "$rc" -ne 0 ]; then
  output_error "󰜡" "API request failed"
  exit 0
fi

fh_pct=$(echo "$data" | jq -r '.five_hour.utilization // 0 | round')
sd_pct=$(echo "$data" | jq -r '.seven_day.utilization // 0 | round')
fh_reset=$(echo "$data" | jq -r '.five_hour.resets_at // empty')
sd_reset=$(echo "$data" | jq -r '.seven_day.resets_at // empty')

fh_eta="--"
sd_eta="--"
if [ -n "$fh_reset" ]; then
  fh_ts=$(date -d "$fh_reset" +%s 2>/dev/null)
  [ -n "$fh_ts" ] && fh_eta=$(format_eta "$fh_ts")
fi
if [ -n "$sd_reset" ]; then
  sd_ts=$(date -d "$sd_reset" +%s 2>/dev/null)
  [ -n "$sd_ts" ] && sd_eta=$(format_eta "$sd_ts")
fi

cls=$(css_class "$fh_pct")
rl_note=""
if [ "$rate_limited" -eq 1 ]; then
  rl_note="\n⚠ Rate limited — showing cached data"
fi
tooltip="Claude Code Usage\n━━━━━━━━━━━━━━━━━━━━━━━━\n5h:  ${fh_pct}%  ${fh_eta}\n7d:  ${sd_pct}%  ${sd_eta}${rl_note}"

printf '{"text":"󰜡 %s%%","tooltip":"%s","class":"%s","percentage":%s}\n' \
  "$fh_pct" "$tooltip" "$cls" "$fh_pct"

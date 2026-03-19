#!/usr/bin/env bash
# Codex CLI usage for waybar — reads OAuth token from ~/.codex/auth.json

# shellcheck disable=SC1090,SC1091
source "${AI_USAGE_COMMON:?AI_USAGE_COMMON not set}"

AUTH_FILE="$HOME/.codex/auth.json"
if [ ! -f "$AUTH_FILE" ]; then
  output_error "󰚩" "No auth file"
  exit 0
fi

force_refresh=0
if [ "${1:-}" = "--force-refresh" ]; then
  force_refresh=1
elif [ "${1:-}" = "--restart" ]; then
  clear_usage_cache "codex"
  force_refresh=1
fi

fetch_data() {
  local token response http_code
  token=$(jq -r '.tokens.access_token' "$AUTH_FILE")
  response=$(curl -s -w '\n%{http_code}' "https://chatgpt.com/backend-api/wham/usage" \
    -H "Authorization: Bearer $token")
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
data=$(get_cached_or_fetch "codex" 300 "$force_refresh")
rc=$?
if [ "$rc" -eq 3 ]; then
  rate_limited=1
elif [ "$rc" -eq 2 ]; then
  output_error "󰚩" "Rate limited (no cache)"
  exit 0
elif [ "$rc" -ne 0 ]; then
  output_error "󰚩" "API request failed"
  exit 0
fi

fh_pct=$(echo "$data" | jq -r '.rate_limit.primary_window.used_percent // 0 | round')
sd_pct=$(echo "$data" | jq -r '.rate_limit.secondary_window.used_percent // 0 | round')
fh_reset_ts=$(echo "$data" | jq -r '.rate_limit.primary_window.reset_at // empty')
sd_reset_ts=$(echo "$data" | jq -r '.rate_limit.secondary_window.reset_at // empty')

fh_eta="--"
sd_eta="--"
[ -n "$fh_reset_ts" ] && fh_eta=$(format_eta "$fh_reset_ts")
[ -n "$sd_reset_ts" ] && sd_eta=$(format_eta "$sd_reset_ts")

cls=$(css_class "$fh_pct")
rl_note=""
if [ "$rate_limited" -eq 1 ]; then
  rl_note="\n⚠ Rate limited — showing cached data"
fi
tooltip="Codex CLI Usage\n━━━━━━━━━━━━━━━━━━━━━━━━\n5h:  ${fh_pct}%  ${fh_eta}\n7d:  ${sd_pct}%  ${sd_eta}${rl_note}"

# At 100%: show reset timer instead of percentage (7d takes priority)
bar_text="${fh_pct}%"
if [ "$sd_pct" -ge 100 ]; then
  bar_text="${sd_eta}"
elif [ "$fh_pct" -ge 100 ]; then
  bar_text="${fh_eta}"
fi

printf '{"text":"󰚩 %s","tooltip":"%s","class":"%s","percentage":%s}\n' \
  "$bar_text" "$tooltip" "$cls" "$fh_pct"

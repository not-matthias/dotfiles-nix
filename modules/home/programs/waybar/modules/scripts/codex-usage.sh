#!/usr/bin/env bash
# Codex CLI usage for waybar — queries usage via `omp usage -p openai-codex --json`

# shellcheck disable=SC1090,SC1091
source "${AI_USAGE_COMMON:?AI_USAGE_COMMON not set}"

force_refresh=0
if [ "${1:-}" = "--force-refresh" ]; then
  force_refresh=1
  omp usage invalidate -p openai-codex >/dev/null 2>&1 || true
elif [ "${1:-}" = "--restart" ]; then
  clear_usage_cache "codex"
  force_refresh=1
  omp usage invalidate -p openai-codex >/dev/null 2>&1 || true
fi

fetch_data() {
  local json
  if ! json=$(omp usage -p openai-codex --json 2>/dev/null); then
    return 1
  fi
  local count
  count=$(echo "$json" | jq -r '([.reports[]? | select(.provider == "openai-codex")] | length) // 0' 2>/dev/null)
  if [ -z "$count" ] || [ "$count" -eq 0 ]; then
    return 4
  fi
  echo "$json"
  return 0
}

rate_limited=0
data=$(get_cached_or_fetch "codex" "${AI_USAGE_REFRESH_SECONDS:-600}" "$force_refresh")
rc=$?
if [ "$rc" -eq 3 ]; then
  rate_limited=1
elif [ "$rc" -eq 2 ]; then
  output_error "󰚩" "Rate limited (no cache)"
  exit 0
elif [ "$rc" -eq 4 ]; then
  output_error "󰚩" "No Codex account found; check omp auth"
  exit 0
elif [ "$rc" -ne 0 ]; then
  output_error "󰚩" "Failed to fetch usage"
  exit 0
fi

fh_pct=$(echo "$data" | jq -r '([.reports[]? | select(.provider == "openai-codex") | .limits[]? | select(.scope.windowId == "5h" and ((.scope.tier // "") != "spark"))][0] | .amount.used // empty | round) // empty')
fh_reset=$(echo "$data" | jq -r '([.reports[]? | select(.provider == "openai-codex") | .limits[]? | select(.scope.windowId == "5h" and ((.scope.tier // "") != "spark"))][0] | .window.resetsAt // empty)')

sd_pct=$(echo "$data" | jq -r '([.reports[]? | select(.provider == "openai-codex") | .limits[]? | select((.scope.windowId == "7d" or .id == "openai-codex:primary") and ((.scope.tier // "") != "spark"))][0] | .amount.used // 0 | round)')
sd_reset=$(echo "$data" | jq -r '([.reports[]? | select(.provider == "openai-codex") | .limits[]? | select((.scope.windowId == "7d" or .id == "openai-codex:primary") and ((.scope.tier // "") != "spark"))][0] | .window.resetsAt // empty)')

spark_pct=$(echo "$data" | jq -r '([.reports[]? | select(.provider == "openai-codex") | .limits[]? | select(.scope.tier == "spark" or ((.label // "") | ascii_downcase | contains("spark")))][0] | .amount.used // empty | round) // empty')
spark_reset=$(echo "$data" | jq -r '([.reports[]? | select(.provider == "openai-codex") | .limits[]? | select(.scope.tier == "spark" or ((.label // "") | ascii_downcase | contains("spark")))][0] | .window.resetsAt // empty)')

fh_eta="--"
sd_eta="--"
spark_eta="--"
[ -n "$fh_reset" ] && [ "$fh_reset" != "null" ] && fh_eta=$(format_eta "$fh_reset")
[ -n "$sd_reset" ] && [ "$sd_reset" != "null" ] && sd_eta=$(format_eta "$sd_reset")
[ -n "$spark_reset" ] && [ "$spark_reset" != "null" ] && spark_eta=$(format_eta "$spark_reset")

cls=$(css_class "${fh_pct:-$sd_pct}")
rl_note=""
if [ "$rate_limited" -eq 1 ]; then
  rl_note="\n⚠ Showing cached data"
fi

tooltip="Codex CLI Usage\n━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -n "$fh_pct" ]; then
  tooltip="${tooltip}\n5h:     ${fh_pct}%  ${fh_eta}"
fi
tooltip="${tooltip}\n7d:    ${sd_pct}%  ${sd_eta}"
if [ -n "$spark_pct" ]; then
  tooltip="${tooltip}\nSpark:  ${spark_pct}%  ${spark_eta}"
fi
tooltip="${tooltip}${rl_note}"

main_pct="${fh_pct:-$sd_pct}"
bar_text="${main_pct}%"
if [ "$sd_pct" -ge 100 ]; then
  bar_text="${sd_eta}"
elif [ -n "$fh_pct" ] && [ "$fh_pct" -ge 100 ]; then
  bar_text="${fh_eta}"
fi

printf '{"text":"󰚩 %s","tooltip":"%s","class":"%s","percentage":%s}\n' \
  "$bar_text" "$tooltip" "$cls" "$main_pct"

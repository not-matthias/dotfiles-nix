#!/usr/bin/env bash
# Claude Code usage for waybar — queries usage via `omp usage -p anthropic --json`

# shellcheck disable=SC1090,SC1091
source "${AI_USAGE_COMMON:?AI_USAGE_COMMON not set}"

force_refresh=0
if [ "${1:-}" = "--force-refresh" ]; then
  force_refresh=1
  omp usage invalidate -p anthropic >/dev/null 2>&1 || true
elif [ "${1:-}" = "--restart" ]; then
  clear_usage_cache "claude"
  force_refresh=1
  omp usage invalidate -p anthropic >/dev/null 2>&1 || true
fi

fetch_data() {
  local json
  if ! json=$(omp usage -p anthropic --json 2>/dev/null); then
    return 1
  fi
  local count
  count=$(echo "$json" | jq -r '([.reports[]? | select(.provider == "anthropic")] | length) // 0' 2>/dev/null)
  if [ -z "$count" ] || [ "$count" -eq 0 ]; then
    return 4
  fi
  echo "$json"
  return 0
}

rate_limited=0
data=$(get_cached_or_fetch "claude" "${AI_USAGE_REFRESH_SECONDS:-600}" "$force_refresh")
rc=$?
if [ "$rc" -eq 3 ]; then
  rate_limited=1
elif [ "$rc" -eq 2 ]; then
  output_error "󰜡" "Rate limited (no cache)"
  exit 0
elif [ "$rc" -eq 4 ]; then
  output_error "󰜡" "No Claude account found; check omp auth"
  exit 0
elif [ "$rc" -ne 0 ]; then
  output_error "󰜡" "Failed to fetch usage"
  exit 0
fi

fh_pct=$(echo "$data" | jq -r '([.reports[]? | select(.provider == "anthropic") | .limits[]? | select(.scope.windowId == "5h" and (.scope.shared == true or .scope.shared == null))][0] | .amount.used // 0) | round')
sd_pct=$(echo "$data" | jq -r '([.reports[]? | select(.provider == "anthropic") | .limits[]? | select(.scope.windowId == "7d" and (.scope.shared == true or .scope.shared == null))][0] | .amount.used // 0) | round')
fh_reset=$(echo "$data" | jq -r '([.reports[]? | select(.provider == "anthropic") | .limits[]? | select(.scope.windowId == "5h" and (.scope.shared == true or .scope.shared == null))][0] | .window.resetsAt // empty)')
sd_reset=$(echo "$data" | jq -r '([.reports[]? | select(.provider == "anthropic") | .limits[]? | select(.scope.windowId == "7d" and (.scope.shared == true or .scope.shared == null))][0] | .window.resetsAt // empty)')

fh_eta="--"
sd_eta="--"
[ -n "$fh_reset" ] && [ "$fh_reset" != "null" ] && fh_eta=$(format_eta "$fh_reset")
[ -n "$sd_reset" ] && [ "$sd_reset" != "null" ] && sd_eta=$(format_eta "$sd_reset")

model_line() {
  local label="$1" pct="$2" reset="$3" eta="--"
  if [ -n "$reset" ] && [ "$reset" != "null" ]; then
    eta=$(format_eta "$reset")
  fi
  printf '%-7s %3s%%  %s' "$label" "$pct" "$eta"
}

get_anthropic_model() {
  local name="$1" field="$2"
  echo "$data" | jq -r --arg name "$name" --arg field "$field" '
    ([.reports[]? | select(.provider == "anthropic") | .limits[]? | select(
      ((.scope.tier // "") | ascii_downcase == $name) or
      ((.label // "") | ascii_downcase | contains($name))
    )][0] | if $field == "pct" then ((.amount.used // empty) | round) else (.window.resetsAt // empty) end) // empty
  '
}

sonnet_pct=$(get_anthropic_model "sonnet" "pct")
sonnet_reset=$(get_anthropic_model "sonnet" "reset")
opus_pct=$(get_anthropic_model "opus" "pct")
opus_reset=$(get_anthropic_model "opus" "reset")
cowork_pct=$(get_anthropic_model "cowork" "pct")
cowork_reset=$(get_anthropic_model "cowork" "reset")
fable_pct=$(get_anthropic_model "fable" "pct")
fable_reset=$(get_anthropic_model "fable" "reset")

models_tooltip="\n\nModels (7d scoped)\n$(model_line "Sonnet:" "${sonnet_pct:-0}" "$sonnet_reset")\n$(model_line "Opus:" "${opus_pct:-0}" "$opus_reset")\n$(model_line "Cowork:" "${cowork_pct:-0}" "$cowork_reset")\n$(model_line "Fable:" "${fable_pct:-0}" "$fable_reset")"

cls=$(css_class "$fh_pct")
rl_note=""
if [ "$rate_limited" -eq 1 ]; then
  rl_note="\n⚠ Showing cached data"
fi

# Fetch 2x promo status (best-effort, don't block on failure)
twox_note=""
twox_json=$(curl -s --max-time 3 "https://isclaude2x.com/json" 2>/dev/null || true)
if [ -n "$twox_json" ]; then
  is2x=$(echo "$twox_json" | jq -r '.is2x // false')
  promo_active=$(echo "$twox_json" | jq -r '.promoActive // false')
  if [ "$promo_active" = "true" ]; then
    if [ "$is2x" = "true" ]; then
      expires_in=$(echo "$twox_json" | jq -r '.["2xWindowExpiresIn"] // ""')
      twox_note="\n🐇 2× active"
      [ -n "$expires_in" ] && twox_note="${twox_note} (expires in ${expires_in})"
    else
      std_expires=$(echo "$twox_json" | jq -r '.standardWindowExpiresIn // ""')
      twox_note="\n🐢 1× mode"
      [ -n "$std_expires" ] && twox_note="${twox_note} (2× in ${std_expires})"
    fi
  fi
fi

tooltip="Claude Code Usage\n━━━━━━━━━━━━━━━━━━━━━━━━\n5h:  ${fh_pct}%  ${fh_eta}\n7d:  ${sd_pct}%  ${sd_eta}${models_tooltip}${twox_note}${rl_note}"

# At 100%: show reset timer instead of percentage (7d takes priority)
bar_text="${fh_pct}%"
if [ "$sd_pct" -ge 100 ]; then
  bar_text="${sd_eta}"
elif [ "$fh_pct" -ge 100 ]; then
  bar_text="${fh_eta}"
fi

printf '{"text":"󰜡 %s","tooltip":"%s","class":"%s","percentage":%s}\n' \
  "$bar_text" "$tooltip" "$cls" "$fh_pct"

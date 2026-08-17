#!/usr/bin/env bash
# Google Antigravity usage for waybar — queries usage via `omp usage -p google-antigravity --json`

# shellcheck disable=SC1090,SC1091
source "${AI_USAGE_COMMON:?AI_USAGE_COMMON not set}"

force_refresh=0
if [ "${1:-}" = "--force-refresh" ]; then
  force_refresh=1
  omp usage invalidate -p google-antigravity >/dev/null 2>&1 || true
elif [ "${1:-}" = "--restart" ]; then
  clear_usage_cache "antigravity"
  force_refresh=1
  omp usage invalidate -p google-antigravity >/dev/null 2>&1 || true
fi

fetch_data() {
  local json
  if ! json=$(omp usage -p google-antigravity --json 2>/dev/null); then
    return 1
  fi
  local count
  count=$(echo "$json" | jq -r '([.reports[]? | select(.provider == "google-antigravity")] | length) // 0' 2>/dev/null)
  if [ -z "$count" ] || [ "$count" -eq 0 ]; then
    return 4
  fi
  echo "$json"
  return 0
}

rate_limited=0
data=$(get_cached_or_fetch "antigravity" "${AI_USAGE_REFRESH_SECONDS:-600}" "$force_refresh")
rc=$?
if [ "$rc" -eq 3 ]; then
  rate_limited=1
elif [ "$rc" -eq 2 ]; then
  output_error "󰛖" "Rate limited (no cache)"
  exit 0
elif [ "$rc" -eq 4 ]; then
  output_error "󰛖" "No Antigravity account found; check omp auth"
  exit 0
elif [ "$rc" -ne 0 ]; then
  output_error "󰛖" "Failed to fetch usage"
  exit 0
fi

reports_json=$(echo "$data" | jq -c '[.reports[]? | select(.provider == "google-antigravity")]')
num_reports=$(echo "$reports_json" | jq 'length')

tooltip="Google Antigravity Usage\n━━━━━━━━━━━━━━━━━━━━━━━━"
max_pct=0
max_100_eta=""

first_report=1
while IFS= read -r report; do
  [ -z "$report" ] && continue
  email=$(echo "$report" | jq -r '.metadata.email // empty')
  if [ "$num_reports" -gt 1 ] && [ -n "$email" ]; then
    if [ "$first_report" -eq 1 ]; then
      tooltip="${tooltip}\n${email}:"
      first_report=0
    else
      tooltip="${tooltip}\n\n${email}:"
    fi
  fi

  limits_json=$(echo "$report" | jq -c '.limits[]?')
  while IFS= read -r limit; do
    [ -z "$limit" ] && continue
    lbl=$(echo "$limit" | jq -r '.label // ""')
    model=$(echo "$lbl" | sed -e 's/^Usage (//' -e 's/)//')
    win=$(echo "$limit" | jq -r '.window.label // .scope.windowId // ""')
    case "${win,,}" in
      weekly|7d) win_str="Weekly" ;;
      daily|1d) win_str="Daily" ;;
      *) win_str="$win" ;;
    esac

    used=$(echo "$limit" | jq -r '(.amount.used // 0) | round')
    resets_at=$(echo "$limit" | jq -r '.window.resetsAt // empty')
    eta="--"
    if [ -n "$resets_at" ] && [ "$resets_at" != "null" ]; then
      eta=$(format_eta "$resets_at")
    fi

    name="${model} (${win_str}):"
    if [ "$num_reports" -gt 1 ]; then
      line=$(printf '%-22s %3s%%  %s' "$name" "$used" "$eta")
      tooltip="${tooltip}\n  ${line}"
    else
      line=$(printf '%-22s %3s%%  %s' "$name" "$used" "$eta")
      tooltip="${tooltip}\n${line}"
    fi

    if [ "$used" -gt "$max_pct" ]; then
      max_pct="$used"
    fi
    if [ "$used" -ge 100 ] && [ -z "$max_100_eta" ] && [ "$eta" != "--" ]; then
      max_100_eta="$eta"
    fi
  done <<< "$limits_json"
done <<< "$(echo "$reports_json" | jq -c '.[]')"

cls=$(css_class "$max_pct")
rl_note=""
if [ "$rate_limited" -eq 1 ]; then
  rl_note="\n\n⚠ Showing cached data"
fi
tooltip="${tooltip}${rl_note}"

bar_text="${max_pct}%"
if [ -n "$max_100_eta" ]; then
  bar_text="$max_100_eta"
fi

printf '{"text":"󰛖 %s","tooltip":"%s","class":"%s","percentage":%s}\n' \
  "$bar_text" "$tooltip" "$cls" "$max_pct"

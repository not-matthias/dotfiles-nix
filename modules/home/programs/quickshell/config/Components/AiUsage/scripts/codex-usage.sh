#!/usr/bin/env bash
# Codex CLI usage — queries usage via `omp usage -p openai-codex --json`

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

# One "|"-separated line per account: email, then used % and reset for 5h, 7d and Spark.
# 5h and Spark are empty when the plan has no such limit.
accounts=$(echo "$data" | jq -r '
  def first_limit(f): [.limits[]? | select(f)][0];
  def optional_used: if .amount.used == null then "" else (.amount.used | round) end;
  def reset: .window.resetsAt // "";
  .reports[]? | select(.provider == "openai-codex")
  | first_limit(.scope.windowId == "5h" and ((.scope.tier // "") != "spark")) as $fh
  | first_limit((.scope.windowId == "7d" or .id == "openai-codex:primary") and ((.scope.tier // "") != "spark")) as $sd
  | first_limit(.scope.tier == "spark" or ((.label // "") | ascii_downcase | contains("spark"))) as $spark
  | [.metadata.email // "", ($fh | optional_used), ($fh | reset), (($sd.amount.used // 0) | round), ($sd | reset), ($spark | optional_used), ($spark | reset)]
  | map(tostring) | join("|")')
num_accounts=$(grep -c . <<< "$accounts")

header="Codex CLI Usage"
indent=""
if [ "$num_accounts" -gt 1 ]; then
  header="${header} (${num_accounts} accounts)"
  indent="  "
fi

tooltip="${header}\n━━━━━━━━━━━━━━━━━━━━━━━━"
account_sep=""
candidates=""
while IFS='|' read -r email fh_pct fh_reset sd_pct sd_reset spark_pct spark_reset; do
  if [ "$num_accounts" -gt 1 ]; then
    tooltip="${tooltip}${account_sep}\n${email}"
    account_sep="\n"
  fi
  if [ -n "$fh_pct" ]; then
    tooltip="${tooltip}\n${indent}5h:     ${fh_pct}%  $(format_eta "$fh_reset")"
  fi
  tooltip="${tooltip}\n${indent}7d:    ${sd_pct}%  $(format_eta "$sd_reset")"
  if [ -n "$spark_pct" ]; then
    tooltip="${tooltip}\n${indent}Spark:  ${spark_pct}%  $(format_eta "$spark_reset")"
  fi

  # At 100%: the account waits for its reset (7d takes priority)
  limited=1
  if [ "$sd_pct" -ge 100 ]; then
    limit_reset="$sd_reset"
  elif [ -n "$fh_pct" ] && [ "$fh_pct" -ge 100 ]; then
    limit_reset="$fh_reset"
  else
    limited=0
    limit_reset=""
  fi
  candidates="${candidates}${fh_pct:-$sd_pct}|${limited}|${limit_reset}"$'\n'
done <<< "$accounts"

IFS='|' read -r bar_text bar_pct <<< "$(printf '%s' "$candidates" | pick_bar_account)"
if [ "$num_accounts" -gt 1 ]; then
  bar_text="${bar_text} ×${num_accounts}"
fi

cls=$(css_class "$bar_pct")
rl_note=""
if [ "$rate_limited" -eq 1 ]; then
  rl_note="\n⚠ Showing cached data"
fi
tooltip="${tooltip}${rl_note}"

printf '{"text":"󰚩 %s","tooltip":"%s","class":"%s","percentage":%s}\n' \
  "$bar_text" "$tooltip" "$cls" "$bar_pct"

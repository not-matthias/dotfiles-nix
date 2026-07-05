#!/usr/bin/env bash

# shellcheck disable=SC1090,SC1091
source "${AI_USAGE_COMMON:?AI_USAGE_COMMON not set}"

force_refresh=0
if [ "${1:-}" = "--force-refresh" ]; then
  force_refresh=1
elif [ "${1:-}" = "--restart" ]; then
  clear_usage_cache "umans"
  force_refresh=1
fi
cache_file="$CACHE_DIR/umans.json"
ttl="${AI_USAGE_REFRESH_SECONDS:-300}"
stale_note=""
data_source="fresh"
mkdir -p "$CACHE_DIR"

if [ "$force_refresh" != "1" ] && [ -f "$cache_file" ]; then
  age=$(( $(date +%s) - $(stat -c %Y "$cache_file") ))
  if [ "$age" -lt "$ttl" ]; then
    data=$(cat "$cache_file")
    data_source="cache"
  fi
fi

if [ -z "${data+x}" ]; then
  error_file=$(mktemp)
  if data=$(umans usage --json 2>"$error_file"); then
    data_source="fresh"
  else
    cli_error=$(cat "$error_file")
    rm -f "$error_file"
    if [ -f "$cache_file" ] && [[ "$cli_error" =~ (API[[:space:]]error:[[:space:]]429|Failed[[:space:]]to[[:space:]]fetch[[:space:]]usage:) ]]; then
      data=$(cat "$cache_file")
      data_source="cache"
      stale_note="\n⚠ Showing cached UMANS data"
    else
      output_error "U" "UMANS CLI usage unavailable"
      exit 0
    fi
  fi
  rm -f "$error_file"
fi

if ! parsed=$(echo "$data" | jq -er '
  if type != "object" then
    halt_error(1)
  else
    [
      ((.usage.concurrent_sessions // 0) | tonumber? // 0),
      ((.limits.concurrency.limit // .limits.concurrency.hard_cap // 0) | tonumber? // 0),
      (if .limits.concurrency.hard_cap == null then "--" else ((.limits.concurrency.hard_cap | tonumber?) // "--") end),
      ((.usage.requests_in_window // 0) | tonumber? // 0),
      (if .limits.requests.limit == null then "--" else ((.limits.requests.limit | tonumber?) // "--") end),
      (if .limits.requests.hard_cap == null then "--" else ((.limits.requests.hard_cap | tonumber?) // "--") end),
      ((.usage.tokens_in // 0) | tonumber? // 0),
      ((.usage.tokens_out // 0) | tonumber? // 0),
      (if .window.remaining_minutes == null then "--" else ((.window.remaining_minutes | tonumber?) // "--") end),
      (if .usage.priority.low == true then "yes" else "no" end),
      (.usage.priority.boxed_until // "--")
    ] | @tsv
  end
' 2>/dev/null); then
  clear_usage_cache "umans"
  output_error "U" "Invalid UMANS CLI response"
  exit 0
fi

if [ "$data_source" = "fresh" ]; then
  printf '%s\n' "$data" > "$cache_file"
fi

IFS=$'\t' read -r used limit concurrency_burst requests_used requests_limit requests_burst tokens_in tokens_out reset_minutes priority_low boxed_until <<< "$parsed"

raw_percentage=0
percentage=0
limit_text="--"
text="U ${used}"
if [ "$limit" -gt 0 ]; then
  raw_percentage=$((used * 100 / limit))
  percentage="$raw_percentage"
  if [ "$percentage" -gt 100 ]; then
    percentage=100
  fi
  limit_text="$limit"
  text="U ${used}/${limit}"
fi

class=$(css_class "$percentage")
if [ "$priority_low" = "yes" ] || [ "$raw_percentage" -ge 80 ]; then
  class="high"
fi

tooltip="UMANS Usage\n━━━━━━━━━━━━━━━━━━━━━━━━\nin use: ${used}/${limit_text}\nconcurrency burst: ${concurrency_burst}\nrequests: ${requests_used}/${requests_limit}\nrequests burst: ${requests_burst}\ntokens: ${tokens_in} in / ${tokens_out} out\nreset minutes: ${reset_minutes}\npriority reduced: ${priority_low}\nboxed until: ${boxed_until}${stale_note}"

printf '{"text":"%s","tooltip":"%s","class":"%s","percentage":%s}\n' \
  "$text" "$tooltip" "$class" "$percentage"

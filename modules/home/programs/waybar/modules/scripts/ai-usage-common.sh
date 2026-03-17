#!/usr/bin/env bash
# Shared utilities for AI usage waybar modules

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-ai-usage"

get_retry_limit() {
  local retry_limit="${AI_USAGE_RETRY_LIMIT:-3}"
  if ! [[ "$retry_limit" =~ ^[0-9]+$ ]] || [ "$retry_limit" -lt 1 ]; then
    retry_limit=3
  fi

  echo "$retry_limit"
}

get_base_backoff_seconds() {
  local base_backoff="${AI_USAGE_BACKOFF_BASE_SECONDS:-1}"
  if ! [[ "$base_backoff" =~ ^[0-9]+$ ]] || [ "$base_backoff" -lt 1 ]; then
    base_backoff=1
  fi

  echo "$base_backoff"
}

clear_usage_cache() {
  local name="$1"
  local cache_file="$CACHE_DIR/$name.json"
  rm -f "$cache_file"
}

fetch_data_with_retries() {
  local retry_limit
  retry_limit=$(get_retry_limit)

  local base_backoff
  base_backoff=$(get_base_backoff_seconds)

  local attempt=1
  local backoff="$base_backoff"
  local output
  local http_code

  while [ "$attempt" -le "$retry_limit" ]; do
    if output=$(fetch_data 2>&1); then
      echo "$output"
      return 0
    fi
    http_code="${LAST_HTTP_CODE:-0}"

    if [ "$http_code" = "429" ]; then
      echo "rate_limited" >&2
      return 2
    fi

    if [ "$attempt" -ge "$retry_limit" ]; then
      echo "$output" >&2
      return 1
    fi

    sleep "$backoff"
    backoff=$((backoff * 2))
    attempt=$((attempt + 1))
  done
}

format_eta() {
  local reset_ts="$1"
  local now
  now=$(date +%s)
  local diff=$((reset_ts - now))

  if [ "$diff" -le 0 ]; then
    echo "0m"
    return
  fi

  if [ "$diff" -ge 86400 ]; then
    local days=$((diff / 86400))
    local hours=$(( (diff % 86400) / 3600 ))
    printf "%dd%02dh" "$days" "$hours"
  elif [ "$diff" -ge 3600 ]; then
    local hours=$((diff / 3600))
    local mins=$(( (diff % 3600) / 60 ))
    printf "%dh%02dm" "$hours" "$mins"
  else
    local mins=$((diff / 60))
    printf "%dm" "$mins"
  fi
}

# Cache wrapper: calls fetch_data() (defined by caller), caches result for $ttl seconds
get_cached_or_fetch() {
  local name="$1"
  local ttl="${2:-60}"
  local force_refresh="${3:-0}"
  local cache_file="$CACHE_DIR/$name.json"

  mkdir -p "$CACHE_DIR"

  if [ "$force_refresh" != "1" ] && [ -f "$cache_file" ]; then
    local age
    age=$(( $(date +%s) - $(stat -c %Y "$cache_file") ))
    if [ "$age" -lt "$ttl" ]; then
      cat "$cache_file"
      return 0
    fi
  fi

  local data
  local rc
  data=$(fetch_data_with_retries) ; rc=$?

  if [ "$rc" -eq 2 ]; then
    # Rate limited — return stale cache if available
    if [ -f "$cache_file" ]; then
      cat "$cache_file"
      return 3
    fi
    return 2
  elif [ "$rc" -ne 0 ]; then
    echo "$data" >&2
    return 1
  fi

  echo "$data" > "$cache_file"
  echo "$data"
}

output_error() {
  local icon="$1"
  local msg="$2"
  printf '{"text":"%s Err","tooltip":"%s","class":"critical"}\n' "$icon" "$msg"
}

css_class() {
  local pct="$1"
  if [ "$pct" -ge 80 ]; then
    echo "high"
  elif [ "$pct" -ge 50 ]; then
    echo "mid"
  else
    echo "low"
  fi
}

{
  pkgs,
  cfg,
}: let
  script = pkgs.writeShellApplication {
    name = "flashgen-word-of-hour";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.jq
      pkgs.sqlite
      pkgs.xdg-utils
    ];
    text = ''
            emit() {
              local text="$1"
              local tooltip="$2"
              local class="$3"
              jq -cn --arg text "$text" --arg tooltip "$tooltip" --arg class "$class" '{text: $text, tooltip: $tooltip, class: $class}'
            }

            DB_PATH="''${FLASHGEN_DB_PATH:-${cfg.dbPath}}"
            HSK_LEVEL="''${FLASHGEN_HSK_LEVEL:-${toString cfg.hskLevel}}"
            HSK_VERSION="''${FLASHGEN_HSK_VERSION:-${toString cfg.hskVersion}}"
            action="''${1:-}"

            if [ "$action" = "--open" ]; then
              if [ -e "$DB_PATH" ]; then
                data_dir="$(dirname "$DB_PATH")"
                xdg-open "$(dirname "$data_dir")"
              fi
              exit 0
            fi

            if [ ! -r "$DB_PATH" ]; then
              emit "" "Flashgen DB is not readable: $DB_PATH" "unavailable"
              exit 0
            fi

            case "$HSK_LEVEL" in
              ""|*[!0-9]*)
                emit "" "Flashgen HSK level must be numeric, got: $HSK_LEVEL" "unavailable"
                exit 0
                ;;
            esac

            case "$HSK_VERSION" in
              2) column="hsk20_level" ;;
              3) column="hsk_level" ;;
              *)
                emit "" "Flashgen HSK version must be 2 or 3, got: $HSK_VERSION" "unavailable"
                exit 0
                ;;
            esac

            if ! count="$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM words WHERE $column = $HSK_LEVEL;")"; then
              emit "" "Flashgen DB query failed: $DB_PATH" "unavailable"
              exit 0
            fi

            case "$count" in
              ""|*[!0-9]*)
                emit "" "Flashgen DB returned an invalid word count: $count" "unavailable"
                exit 0
                ;;
            esac

            if [ "$count" -eq 0 ]; then
              emit "" "No Flashgen words found for HSK $HSK_LEVEL v$HSK_VERSION" "unavailable"
              exit 0
            fi

            if [ -n "$action" ]; then
              emit "" "Unknown Flashgen action: $action" "unavailable"
              exit 0
            fi

            offset=$(shuf -i 0-$((count - 1)) -n 1)
            if ! row="$(sqlite3 -separator $'\t' "$DB_PATH" "SELECT id, simplified, pinyin_display, printf('%s', tags) FROM words WHERE $column = $HSK_LEVEL ORDER BY COALESCE(frequency_rank, 2147483647), id LIMIT 1 OFFSET $offset;")"; then
              emit "" "Flashgen word query failed: $DB_PATH" "unavailable"
              exit 0
            fi
            if [ -z "$row" ]; then
              emit "" "Flashgen returned no word for HSK $HSK_LEVEL v$HSK_VERSION" "unavailable"
              exit 0
            fi

            IFS=$'\t' read -r word_id simplified pinyin tags <<< "$row"

            definition="$(sqlite3 "$DB_PATH" "SELECT printf('%s', group_concat(definition, '; ')) FROM (SELECT definition FROM definitions WHERE word_id = $word_id AND length(trim(definition)) > 0 LIMIT 3);")"
            sentence="$(sqlite3 -separator $'\t' "$DB_PATH" "SELECT chinese, pinyin, english FROM sentences WHERE word_id = $word_id AND length(trim(chinese)) > 0 ORDER BY id LIMIT 1;")"
            display_text="$simplified"

            tooltip="HSK $HSK_LEVEL v$HSK_VERSION • $((offset + 1))/$count
      $simplified
      $pinyin"

            if [ -n "$definition" ]; then
              tooltip="$tooltip
      $definition"
            fi

            if [ -n "$tags" ]; then
              tooltip="$tooltip
      Tags: $tags"
            fi

            if [ -n "$sentence" ]; then
              IFS=$'\t' read -r sentence_zh sentence_py sentence_en <<< "$sentence"
              if [ -n "$sentence_zh" ]; then
                display_text="$display_text · $sentence_zh"
              fi
              tooltip="$tooltip

      Example:
      $sentence_zh
      $sentence_py
      $sentence_en"
            fi

            emit "$display_text" "$tooltip" "word"
    '';
  };
in {
  inherit script;

  config = {
    "custom/flashgen-word" = {
      return-type = "json";
      format = "{text}";
      exec = "${script}/bin/flashgen-word-of-hour";
      on-click = "${pkgs.procps}/bin/pkill -RTMIN+9 waybar";
      on-click-right = "${script}/bin/flashgen-word-of-hour --open";
      signal = 9;
      interval = 3600;
      tooltip = true;
      hide-empty-text = true;
    };
  };
  style = builtins.readFile ./flashgen-word/style.css;
}

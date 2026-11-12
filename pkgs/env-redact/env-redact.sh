#!/usr/bin/env bash
# Print a .env file with values redacted: keeps keys, comments and blank lines,
# and reveals only the first few characters of each value.
set -euo pipefail

show=4
mask='*'
numbers=0
file=

usage() {
	cat <<'EOF'
env-redact: print a .env file with its values redacted

Usage:
  env-redact [OPTIONS] [FILE]

Keys, comments, blank lines and indentation are printed unchanged; only the
values are masked, keeping the first few characters of each one visible.
Quote style is preserved, and a comment trailing a quoted value is kept.

Options:
  -n, --show N     reveal the first N characters of each value (default: 4).
                   Values of N characters or fewer are masked entirely, so a
                   short secret never leaks a meaningful prefix. Use -n 0 to
                   hide every value completely.
  -m, --mask CHAR  single character used for masking (default: *)
  -l, --numbers    prefix each line with its line number
  -h, --help       show this help and exit

Arguments:
  FILE             file to read (default: .env). Use "-" to read stdin.

Examples:
  env-redact                          # redact ./.env
  env-redact -n 6 .env.production     # show a longer prefix
  env-redact -l -n 0 ~/project/.env   # numbered, values fully hidden
  cat .env | env-redact -             # read from a pipe

Note: masking is length-preserving, so the output reveals how long each value
is. Comments are printed verbatim and may themselves hold sensitive details
(vault ids, URLs, account names); review them before sharing the output.

Exit status:
  0  success        1  file not found        2  bad usage
EOF
}

# Translate long options into their short equivalents for getopts.
args=()
for arg in "$@"; do
	case $arg in
	--show) args+=(-n) ;;
	--mask) args+=(-m) ;;
	--numbers | --number) args+=(-l) ;;
	--help) args+=(-h) ;;
	--show=*) args+=(-n "${arg#*=}") ;;
	--mask=*) args+=(-m "${arg#*=}") ;;
	--*)
		echo "env-redact: unknown option $arg" >&2
		usage >&2
		exit 2
		;;
	*) args+=("$arg") ;;
	esac
done
set -- ${args+"${args[@]}"}

while getopts ':n:m:lh' opt; do
	case $opt in
	n) show=$OPTARG ;;
	m) mask=$OPTARG ;;
	l) numbers=1 ;;
	h)
		usage
		exit 0
		;;
	:)
		echo "env-redact: option -$OPTARG requires an argument" >&2
		exit 2
		;;
	*)
		echo "env-redact: unknown option -$OPTARG" >&2
		usage >&2
		exit 2
		;;
	esac
done
shift $((OPTIND - 1))

if [[ ! $show =~ ^[0-9]+$ ]]; then
	echo "env-redact: -n expects a non-negative integer, got '$show'" >&2
	exit 2
fi
if ((${#mask} != 1)); then
	echo "env-redact: -m expects a single character, got '$mask'" >&2
	exit 2
fi

file=${1:-.env}
if [[ $file != - && ! -f $file ]]; then
	echo "env-redact: no such file: $file" >&2
	exit 1
fi
[[ $file == - ]] && file=/dev/stdin

# Repeat $mask $1 times.
repeat() {
	local n=$1 out=''
	while ((n-- > 0)); do out+=$mask; done
	printf '%s' "$out"
}

# Redact a raw value, preserving surrounding quotes and any trailing comment.
redact_value() {
	local raw=$1 trailing='' quote='' body

	# Split off a trailing comment only when the value is quoted; on an
	# unquoted value a '#' is ambiguous, so keep it inside the value.
	if [[ $raw =~ ^([\'\"]) ]]; then
		quote=${BASH_REMATCH[1]}
		if [[ $raw =~ ^${quote}([^${quote}]*)${quote}(.*)$ ]]; then
			body=${BASH_REMATCH[1]}
			trailing=${BASH_REMATCH[2]}
		else
			# Unterminated quote: treat the rest as the value.
			quote=''
			body=$raw
		fi
	else
		body=$raw
	fi

	local n=${#body} visible=''
	if ((n > show)); then
		visible=${body:0:show}
	fi
	printf '%s%s%s%s%s' "$quote" "$visible" "$(repeat $((n - ${#visible})))" "$quote" "$trailing"
}

lines=()
while IFS= read -r line || [[ -n $line ]]; do
	lines+=("$line")
done <"$file"

# Right-align numbers on the widest line number so the keys stay aligned.
width=${#lines[@]}
width=${#width}

n=0
for line in ${lines+"${lines[@]}"}; do
	((++n))
	# Comments, blank lines and anything that is not KEY=VALUE pass through.
	if [[ $line =~ ^[[:space:]]*(export[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*= ]]; then
		out="${line%%=*}=$(redact_value "${line#*=}")"
	else
		out=$line
	fi
	if ((numbers)); then
		printf '%*d  %s\n' "$width" "$n" "$out"
	else
		printf '%s\n' "$out"
	fi
done

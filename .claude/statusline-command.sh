#!/bin/bash
export LC_ALL=C   # force "." decimals so printf '%.2f' works on comma-decimal locales (Linux/EU)
input=$(cat)
MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'; ORANGE='\033[38;5;172m'; BLUE='\033[34m'; RESET='\033[0m'

# Pick bar color based on context usage
if [ "$PCT" -ge 70 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 50 ]; then BAR_COLOR="$YELLOW"
else BAR_COLOR="$GREEN"; fi

FILLED=$((PCT / 8)); EMPTY=$((8 - FILLED))
# Build the bar with a loop, not `tr ' ' '▮'`: GNU tr (Linux) is byte-oriented and mangles
# the multibyte block glyphs into invalid UTF-8. BSD tr (macOS) handled it; GNU tr does not.
BAR=""
for ((i=0; i<FILLED; i++)); do BAR+="▮"; done
for ((i=0; i<EMPTY;  i++)); do BAR+="▯"; done

BRANCH=""
git rev-parse --git-dir > /dev/null 2>&1 && BRANCH="${BLUE}$(git branch --show-current 2>/dev/null)${RESET}"

TIME=$(date +%H:%M)
HOUR=$((10#$(date +%H)))   # base-10 so 00/08/09 don't break (empty string / octal)
# Time color: green 9-20, light blue 6-9, dark red 20-5
if [ "$HOUR" -ge 9 ] && [ "$HOUR" -lt 20 ]; then TIME_COLOR='\033[38;5;71m'
elif [ "$HOUR" -ge 6 ] && [ "$HOUR" -lt 9 ]; then TIME_COLOR='\033[38;5;117m'
else TIME_COLOR='\033[38;5;124m'
fi

COST_FMT=$(printf '$%.2f' "$COST")

echo -e "${ORANGE}${MODEL}${RESET}"
echo -e "${DIR##*/}"
[ -n "$BRANCH" ] && echo -e "${BRANCH}"
echo -e "${TIME_COLOR}${TIME}${RESET} | ${COST_FMT} | ${BAR_COLOR}${BAR}${RESET} ${PCT}%"

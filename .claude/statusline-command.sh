#!/bin/bash
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

BRANCH=""
git --no-optional-locks rev-parse --git-dir > /dev/null 2>&1 && BRANCH="${BLUE}$(git --no-optional-locks branch --show-current 2>/dev/null)${RESET}"

TIME=$(date +%H:%M)
HOUR=$(date +%H | sed 's/^0//')
# Time color: green 9-20, light blue 6-9, dark red 20-5
if [ "$HOUR" -ge 9 ] && [ "$HOUR" -lt 20 ]; then TIME_COLOR='\033[38;5;71m'
elif [ "$HOUR" -ge 6 ] && [ "$HOUR" -lt 9 ]; then TIME_COLOR='\033[38;5;117m'
else TIME_COLOR='\033[38;5;124m'
fi

COST_FMT=$(printf '$%.2f' "$COST")

echo -e "${ORANGE}${MODEL}${RESET} | ${TIME_COLOR}${TIME}${RESET}"
DIR_LINE="${DIR##*/}"
[ -n "$BRANCH" ] && DIR_LINE="$DIR_LINE | ${BRANCH}"
echo -e "$DIR_LINE"
echo -e "${COST_FMT} | context: ${BAR_COLOR}${PCT}%${RESET}"

# Rate limit windows (only present for Claude subscribers, after the first response)
fmt_reset() {
  local resets=${1%.*}
  local now diff d h m
  resets=${resets%Z}
  case $resets in
    *[!0-9]*) resets=$(date -j -u -f '%Y-%m-%dT%H:%M:%S' "$resets" +%s 2>/dev/null) || return 1 ;;
  esac
  [ -n "$resets" ] || return 1
  now=$(date +%s)
  diff=$(( resets - now ))
  [ "$diff" -lt 0 ] && diff=0
  d=$(( diff / 86400 )); h=$(( (diff % 86400) / 3600 )); m=$(( (diff % 3600) / 60 ))
  if [ "$d" -gt 0 ]; then printf '%dd%dh' "$d" "$h"
  elif [ "$h" -gt 0 ]; then printf '%dh%dm' "$h" "$m"
  else printf '%dm' "$m"
  fi
}

pct_color() {
  if [ "$1" -ge 70 ]; then echo "$RED"
  elif [ "$1" -ge 50 ]; then echo "$YELLOW"
  else echo "$GREEN"
  fi
}

FIVE_PCT=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
FIVE_RESETS=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
WEEK_PCT=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
WEEK_RESETS=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

if [ -n "$FIVE_PCT" ]; then
  FIVE_INT=$(printf '%.0f' "$FIVE_PCT")
  FIVE_LINE="$(pct_color "$FIVE_INT")5h ${FIVE_INT}%${RESET}"
  FIVE_IN=$(fmt_reset "$FIVE_RESETS")
  [ -n "$FIVE_IN" ] && FIVE_LINE="$FIVE_LINE resets $FIVE_IN"
  echo -e "$FIVE_LINE"
fi

if [ -n "$WEEK_PCT" ]; then
  WEEK_INT=$(printf '%.0f' "$WEEK_PCT")
  WEEK_LINE="$(pct_color "$WEEK_INT")7d ${WEEK_INT}%${RESET}"
  WEEK_IN=$(fmt_reset "$WEEK_RESETS")
  [ -n "$WEEK_IN" ] && WEEK_LINE="$WEEK_LINE resets $WEEK_IN"
  echo -e "$WEEK_LINE"
fi

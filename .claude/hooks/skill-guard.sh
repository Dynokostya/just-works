#!/bin/bash
# PreToolUse hook for Write, Edit and MultiEdit. Before the first write to a code
# file in a session, it blocks the write once and asks Claude to load the coding
# skills for that file type. A write goes through when the transcript shows the
# skills loaded, or when the session was already asked once. Needs jq; without
# it, every write goes through.
input=$(cat)
file=$(jq -r '.tool_input.file_path // empty' <<<"$input")
case "$file" in
  *.py) lang=python-coding ;;
  *.ts) lang=typescript-coding ;;
  *.tsx|*.jsx) lang=react-coding ;;
  *.swift) lang=swift-coding ;;
  *.cs) lang=csharp-coding ;;
  *) exit 0 ;;
esac

session=$(jq -r '.session_id // empty' <<<"$input")
transcript=$(jq -r '.transcript_path // empty' <<<"$input")
state="${TMPDIR:-/tmp}/just-works-skill-guard"

missing=()
for skill in "$lang" minimal-coding; do
  [[ -e "$state/$session-$skill" ]] && continue
  [[ -f "$transcript" ]] && grep -qE "\"name\":\"Skill\",\"input\":\{\"skill\":\"$skill\"|<command-name>/$skill</command-name>" "$transcript" && continue
  missing+=("$skill")
done
[[ ${#missing[@]} -eq 0 ]] && exit 0

mkdir -p "$state"
for skill in "${missing[@]}"; do touch "$state/$session-$skill"; done
list=$(printf '%s and ' "${missing[@]}")
jq -n --arg reason "Before writing ${file##*/}, load ${list% and } with the Skill tool, then retry this write." \
  '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'

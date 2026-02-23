#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="${HOME}/.claude"
CODEX_HOME="${HOME}/.codex"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

# Flags
PERSONAL=false
DRY_RUN=false
CLAUDE_ONLY=false
CODEX_ONLY=false

# Colors
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    RED='\033[0;31m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    GREEN='' YELLOW='' RED='' BOLD='' NC=''
fi

info()  { echo -e "${GREEN}[+]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[x]${NC} $*" >&2; }

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Install just-works agents, skills, and commands globally.

Options:
  --personal      Use opinionated settings.json (permissions, hooks, sounds)
                  Default: minimal settings.json.default
  --claude-only   Install only Claude Code files (~/.claude/)
  --codex-only    Install only Codex files (~/.codex/)
  --dry-run       Show what would be installed without making changes
  -h, --help      Show this help message

What gets installed:
  ~/.claude/
    agents/       Agent definitions (python-code-writer, prompt-writer)
    skills/       Coding and prompting standards
    commands/     Workflows (project-docs)
    settings.json             Permission and hook configuration
    CLAUDE.md                 Global behavioral instructions
    statusline-command.sh     Status line script

  ~/.codex/
    prompts/      Agent definitions (plan-reviewer, project-docs)
    skills/       Coding and prompting standards
    AGENTS.md     Global behavioral instructions
EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --personal)    PERSONAL=true; shift ;;
        --dry-run)     DRY_RUN=true; shift ;;
        --claude-only) CLAUDE_ONLY=true; shift ;;
        --codex-only)  CODEX_ONLY=true; shift ;;
        -h|--help)     usage ;;
        *) error "Unknown option: $1"; usage ;;
    esac
done

if $CLAUDE_ONLY && $CODEX_ONLY; then
    error "--claude-only and --codex-only are mutually exclusive"
    exit 1
fi

# Choose copy method
if command -v rsync &>/dev/null; then
    copy_dir() { rsync -a "$1/" "$2/"; }
else
    warn "rsync not found — falling back to cp (existing files may be overwritten)"
    copy_dir() { cp -r "$1/." "$2/"; }
fi

backup_file() {
    local target="$1"
    if [[ -f "$target" ]]; then
        local backup="${target}.bak.${TIMESTAMP}"
        if $DRY_RUN; then
            warn "Would back up: $target -> $backup"
        else
            cp "$target" "$backup"
            warn "Backed up: $target -> $backup"
        fi
    fi
}

install_dir() {
    local src="$1" dest="$2" label="$3"
    if [[ ! -d "$src" ]]; then
        warn "Source not found, skipping: $src"
        return
    fi
    if $DRY_RUN; then
        info "Would copy: $src/ -> $dest/"
    else
        mkdir -p "$dest"
        copy_dir "$src" "$dest"
        info "Installed: $label -> $dest/"
    fi
}

install_file() {
    local src="$1" dest="$2" label="$3"
    if [[ ! -f "$src" ]]; then
        warn "Source not found, skipping: $src"
        return
    fi
    backup_file "$dest"
    if $DRY_RUN; then
        info "Would copy: $src -> $dest"
    else
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
        info "Installed: $label -> $dest"
    fi
}

echo -e "${BOLD}just-works installer${NC}"
echo ""

# --- Claude Code ---
if ! $CODEX_ONLY; then
    echo -e "${BOLD}Claude Code${NC}"
    install_dir  "${SCRIPT_DIR}/.claude/agents"   "${CLAUDE_HOME}/agents"   "agents"
    install_dir  "${SCRIPT_DIR}/.claude/skills"    "${CLAUDE_HOME}/skills"   "skills"
    install_dir  "${SCRIPT_DIR}/.claude/commands"  "${CLAUDE_HOME}/commands" "commands"

    if $PERSONAL; then
        install_file "${SCRIPT_DIR}/.claude/settings.json" "${CLAUDE_HOME}/settings.json" "settings.json (personal)"
    else
        install_file "${SCRIPT_DIR}/.claude/settings.json.default" "${CLAUDE_HOME}/settings.json" "settings.json (default)"
    fi

    install_file "${SCRIPT_DIR}/CLAUDE.md" "${CLAUDE_HOME}/CLAUDE.md" "CLAUDE.md"
    install_file "${SCRIPT_DIR}/.claude/statusline-command.sh" "${CLAUDE_HOME}/statusline-command.sh" "statusline-command.sh"
    echo ""
fi

# --- Codex ---
if ! $CLAUDE_ONLY; then
    echo -e "${BOLD}Codex${NC}"
    install_dir  "${SCRIPT_DIR}/.codex/prompts"  "${CODEX_HOME}/prompts"  "prompts"
    install_dir  "${SCRIPT_DIR}/.codex/skills"   "${CODEX_HOME}/skills"   "skills"
    install_file "${SCRIPT_DIR}/AGENTS.md"        "${CODEX_HOME}/AGENTS.md" "AGENTS.md"
    echo ""
fi

# --- Summary ---
if $DRY_RUN; then
    echo -e "${YELLOW}Dry run complete — no files were modified.${NC}"
else
    echo -e "${GREEN}Done.${NC}"
    if ! $CODEX_ONLY; then
        echo "  Claude Code: ${CLAUDE_HOME}/"
    fi
    if ! $CLAUDE_ONLY; then
        echo "  Codex:       ${CODEX_HOME}/"
    fi
fi

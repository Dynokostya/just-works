#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="${HOME}/.claude"
CODEX_HOME="${HOME}/.codex"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="${HOME}/just-works-backups/${TIMESTAMP}"

# Flags
PERSONAL=false
DRY_RUN=false
CLAUDE_ONLY=false
CODEX_ONLY=false
SKIP_CONFIG=false
DO_BACKUP=true

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
  --skip-config   Skip installing config files (settings.json, statusline-command.sh)
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
        --skip-config) SKIP_CONFIG=true; shift ;;
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

echo -e "${BOLD}just-works installer${NC}"
echo ""

# --- Interactive: backup prompt ---
if ! $DRY_RUN; then
    read -rp "Do you want to create backups? (Y/n) " answer
    case "${answer:-Y}" in
        [Yy]*) DO_BACKUP=true ;;
        [Nn]*) DO_BACKUP=false ;;
        *)     DO_BACKUP=true ;;
    esac
    echo ""
fi

# Backup a file or directory to ~/just-works-backups/<datetime>/
backup_target() {
    local target="$1"
    [[ -e "$target" ]] || return 0
    local rel_path="${target#"$HOME"/}"
    local backup_path="${BACKUP_DIR}/${rel_path}"
    if $DRY_RUN; then
        warn "Would back up: $target -> $backup_path"
    else
        mkdir -p "$(dirname "$backup_path")"
        if [[ -d "$target" ]]; then
            mkdir -p "$backup_path"
            copy_dir "$target" "$backup_path"
        else
            cp "$target" "$backup_path"
        fi
        warn "Backed up: $target -> $backup_path"
    fi
}

# Remove a target before fresh copy (clean install without backup)
clean_target() {
    local target="$1"
    [[ -e "$target" ]] || return 0
    if $DRY_RUN; then
        warn "Would remove: $target"
    else
        rm -rf "$target"
        warn "Removed: $target"
    fi
}

# Prepare a target: backup or clean depending on user choice
prepare_target() {
    local target="$1"
    if $DO_BACKUP; then
        backup_target "$target"
    else
        clean_target "$target"
    fi
}

install_dir() {
    local src="$1" dest="$2" label="$3"
    if [[ ! -d "$src" ]]; then
        warn "Source not found, skipping: $src"
        return
    fi
    prepare_target "$dest"
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
    prepare_target "$dest"
    if $DRY_RUN; then
        info "Would copy: $src -> $dest"
    else
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest"
        info "Installed: $label -> $dest"
    fi
}

# --- Claude Code ---
if ! $CODEX_ONLY; then
    echo -e "${BOLD}Claude Code${NC}"
    install_dir  "${SCRIPT_DIR}/.claude/agents"   "${CLAUDE_HOME}/agents"   "agents"
    install_dir  "${SCRIPT_DIR}/.claude/skills"    "${CLAUDE_HOME}/skills"   "skills"
    install_dir  "${SCRIPT_DIR}/.claude/commands"  "${CLAUDE_HOME}/commands" "commands"

    if ! $SKIP_CONFIG; then
        if $PERSONAL; then
            install_file "${SCRIPT_DIR}/.claude/settings.json" "${CLAUDE_HOME}/settings.json" "settings.json (personal)"
        else
            install_file "${SCRIPT_DIR}/.claude/settings.json.default" "${CLAUDE_HOME}/settings.json" "settings.json (default)"
        fi
    else
        info "Skipping settings.json (--skip-config)"
    fi

    install_file "${SCRIPT_DIR}/CLAUDE.md" "${CLAUDE_HOME}/CLAUDE.md" "CLAUDE.md"
    if ! $SKIP_CONFIG; then
        install_file "${SCRIPT_DIR}/.claude/statusline-command.sh" "${CLAUDE_HOME}/statusline-command.sh" "statusline-command.sh"
    else
        info "Skipping statusline-command.sh (--skip-config)"
    fi
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
    if $DO_BACKUP; then
        echo "  Backups:     ${BACKUP_DIR}/"
    fi
    if ! $CODEX_ONLY; then
        echo "  Claude Code: ${CLAUDE_HOME}/"
    fi
    if ! $CLAUDE_ONLY; then
        echo "  Codex:       ${CODEX_HOME}/"
    fi
fi

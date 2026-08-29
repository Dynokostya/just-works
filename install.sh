#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_HOME="${HOME}/.claude"
CODEX_HOME="${HOME}/.codex"
AGENTS_HOME="${HOME}/.agents"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="${HOME}/just-works-backups/${TIMESTAMP}"

# Flags
PERSONAL=false
AZURE=false
DRY_RUN=false
CLAUDE_ONLY=false
CODEX_ONLY=false
SKIP_CONFIG=false
SKIP_STATUSLINE=false
SKIP_SKILLS_CLAUDE=false
SKIP_SKILLS_CODEX=false
DO_BACKUP=true
PRUNE=false
REPLACE_CONFIG=false

# Ownership manifest: records every entry this installer has placed into a
# destination, so --prune can distinguish "we shipped this and it is now gone
# from the source" from "the user put this here". Entries never recorded are
# never deleted.
MANIFEST_FILE="${HOME}/.just-works-manifest"
MANIFEST_NEW="$(mktemp)"
MANIFEST_DESTS="$(mktemp)"
trap 'rm -f "$MANIFEST_NEW" "$MANIFEST_DESTS"' EXIT

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
  --personal      Use opinionated settings (permissions, hooks, sounds)
                  Default: minimal *.default configs
  --azure         Use Azure OpenAI config instead of direct OpenAI API
  --skip-config      Skip installing settings/config files
  --skip-statusline  Skip installing statusline-command.sh
  --skip-skills-claude  Skip installing Claude Code skills
  --skip-skills-codex   Skip installing Codex skills
  --claude-only   Install only Claude Code files (~/.claude/)
  --codex-only    Install only Codex files (~/.codex/, ~/.agents/)
  --dry-run       Show what would be installed without making changes
  --no-backup     Skip backup prompt, disable backups (for CI/non-interactive)
  --prune         Delete entries that a previous run of this installer placed
                  in the destination and that no longer exist in the source
                  (tracked in ~/.just-works-manifest). Entries the installer
                  never shipped are always kept and listed, never deleted.
  --replace-config  Overwrite an existing settings.json / config.toml /
                  hooks.json (with backup). By default existing config files
                  are kept, since live configs accumulate machine-local state
                  (otel, plugin disables, agent defaults) the repo cannot know.
  -h, --help      Show this help message

What gets installed:
  ~/.claude/
    agents/       Agent definitions (python-code-writer, prompt-writer, ...)
    skills/       Coding and prompting standards
    commands/     Workflows (project-docs, git-sync)
    output-styles/  Selectable output styles (compressed, ...)
    settings.json             Permission and hook configuration
    CLAUDE.md                 Global behavioral instructions
    statusline-command.sh     Status line script

  ~/.codex/
    agents/       Custom agent definitions (python-code-writer, diagrammer, ...)
    config.toml   Codex CLI configuration (--azure for Azure OpenAI)
    hooks.json    Lifecycle hooks (notification)
    prompts/      Slash commands (project-docs, git-sync)
    AGENTS.md     Global behavioral instructions

  ~/.agents/
    skills/       Coding and prompting standards (Codex discovery path)
EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --personal)    PERSONAL=true; shift ;;
        --azure)       AZURE=true; shift ;;
        --dry-run)     DRY_RUN=true; shift ;;
        --claude-only) CLAUDE_ONLY=true; shift ;;
        --codex-only)  CODEX_ONLY=true; shift ;;
        --skip-config)     SKIP_CONFIG=true; shift ;;
        --skip-statusline) SKIP_STATUSLINE=true; shift ;;
        --skip-skills-claude) SKIP_SKILLS_CLAUDE=true; shift ;;
        --skip-skills-codex)  SKIP_SKILLS_CODEX=true; shift ;;
        --no-backup)   DO_BACKUP=false; shift ;;
        --prune)       PRUNE=true; shift ;;
        --replace-config) REPLACE_CONFIG=true; shift ;;
        -h|--help)     usage ;;
        *) error "Unknown option: $1"; usage ;;
    esac
done

if $CLAUDE_ONLY && $CODEX_ONLY; then
    error "--claude-only and --codex-only are mutually exclusive"
    exit 1
fi

# Choose copy method. Copies are always additive; deletion happens only through
# the manifest-scoped prune in install_dir, so --prune no longer needs rsync.
if command -v rsync &>/dev/null; then
    copy_dir() { rsync -a "$1/" "$2/"; }
else
    warn "rsync not found — falling back to cp (existing files may be overwritten)"
    copy_dir() { cp -r "$1/." "$2/"; }
fi

echo -e "${BOLD}just-works installer${NC}"
echo ""

# --- Interactive: backup prompt ---
if ! $DRY_RUN && $DO_BACKUP; then
    if [[ -t 0 ]]; then
        read -rp "Do you want to create backups? (Y/n) " answer
        case "${answer:-Y}" in
            [Yy]*) DO_BACKUP=true ;;
            [Nn]*) DO_BACKUP=false ;;
            *)     DO_BACKUP=true ;;
        esac
    else
        warn "Non-interactive mode detected — backups enabled by default"
    fi
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

# Prepare a target: backup or clean depending on user choice.
# Directories are never wholesale-removed: destinations legitimately contain
# user-owned entries (local skills, personal agents) alongside installed ones,
# and staleness is handled per-entry by the manifest prune instead.
prepare_target() {
    local target="$1"
    if $DO_BACKUP; then
        backup_target "$target"
    elif [[ -f "$target" ]]; then
        clean_target "$target"
    fi
}

install_dir() {
    local src="$1" dest="$2" label="$3"
    if [[ ! -d "$src" ]]; then
        warn "Source not found, skipping: $src"
        return
    fi
    echo "$dest" >> "$MANIFEST_DESTS"

    # Split destination extras into ours-but-stale (in the manifest, gone from
    # the source) and user-owned (never shipped by us). Only the former is ever
    # a prune candidate.
    local owned="" stale="" extras="" entry
    if [[ -f "$MANIFEST_FILE" ]]; then
        owned="$(awk -v d="${dest}/" 'index($0, d) == 1 { print substr($0, length(d) + 1) }' "$MANIFEST_FILE")"
    fi
    if [[ -d "$dest" ]]; then
        while IFS= read -r entry; do
            [[ -n "$entry" ]] || continue
            [[ -e "${src}/${entry}" ]] && continue
            if printf '%s\n' "$owned" | grep -Fxq "$entry"; then
                stale="${stale}${entry} "
            else
                extras="${extras}${entry} "
            fi
        done < <(ls "$dest" 2>/dev/null)
    fi
    [[ -n "$extras" ]] && warn "Not managed by this installer, kept in ${dest}: ${extras}"
    if [[ -n "$stale" ]]; then
        if ! $PRUNE; then
            warn "Stale (installed by a previous run, gone from source; use --prune) in ${dest}: ${stale}"
        elif $DRY_RUN; then
            warn "Would prune from ${dest}: ${stale}"
        fi
    fi

    prepare_target "$dest"

    # Prune after the backup so removed entries are still recoverable.
    if $PRUNE && ! $DRY_RUN && [[ -n "$stale" ]]; then
        for entry in $stale; do
            rm -rf "${dest:?}/${entry}"
        done
        warn "Pruned from ${dest}: ${stale}"
    fi

    if $DRY_RUN; then
        info "Would copy: $src/ -> $dest/"
    else
        mkdir -p "$dest"
        copy_dir "$src" "$dest"
        info "Installed: $label -> $dest/"
    fi

    # Claim ownership of everything we ship, whether or not this run is dry:
    # only a real run rewrites the manifest (guarded at the end of the script).
    while IFS= read -r entry; do
        [[ -n "$entry" ]] && echo "${dest}/${entry}" >> "$MANIFEST_NEW"
    done < <(ls "$src" 2>/dev/null)
}

# Config files are kept once they exist: live configs accumulate machine-local
# state (otel routing, plugin disables, subagent defaults) that a repo template
# cannot know about. --replace-config restores the old overwrite behaviour.
install_config_file() {
    local src="$1" dest="$2" label="$3"
    if [[ -f "$dest" ]] && ! $REPLACE_CONFIG; then
        info "Kept existing: $dest (use --replace-config to overwrite)"
        return
    fi
    install_file "$src" "$dest" "$label"
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
    if ! $SKIP_SKILLS_CLAUDE; then
        install_dir  "${SCRIPT_DIR}/.claude/skills"    "${CLAUDE_HOME}/skills"   "skills"
    else
        info "Skipping Claude skills (--skip-skills-claude)"
    fi
    install_dir  "${SCRIPT_DIR}/.claude/commands"  "${CLAUDE_HOME}/commands" "commands"
    install_dir  "${SCRIPT_DIR}/.claude/output-styles"  "${CLAUDE_HOME}/output-styles" "output-styles"
    if $PERSONAL; then
        install_dir  "${SCRIPT_DIR}/.claude/hooks"     "${CLAUDE_HOME}/hooks"    "hooks"
    fi

    if ! $SKIP_CONFIG; then
        if $PERSONAL; then
            install_config_file "${SCRIPT_DIR}/.claude/settings.json" "${CLAUDE_HOME}/settings.json" "settings.json (personal)"
        else
            install_config_file "${SCRIPT_DIR}/.claude/settings.json.default" "${CLAUDE_HOME}/settings.json" "settings.json (default)"
        fi
    else
        info "Skipping settings.json (--skip-config)"
    fi

    install_file "${SCRIPT_DIR}/CLAUDE.md" "${CLAUDE_HOME}/CLAUDE.md" "CLAUDE.md"
    install_file "${SCRIPT_DIR}/CLAUDE-CHAT.md" "${CLAUDE_HOME}/CLAUDE-CHAT.md" "CLAUDE-CHAT.md"
    if ! $SKIP_STATUSLINE; then
        install_file "${SCRIPT_DIR}/.claude/statusline-command.sh" "${CLAUDE_HOME}/statusline-command.sh" "statusline-command.sh"
    else
        info "Skipping statusline-command.sh (--skip-statusline)"
    fi
    echo ""
fi

# --- Codex ---
if ! $CLAUDE_ONLY; then
    echo -e "${BOLD}Codex${NC}"
    install_dir  "${SCRIPT_DIR}/.codex/agents"   "${CODEX_HOME}/agents"   "agents"
    install_dir  "${SCRIPT_DIR}/.codex/prompts"  "${CODEX_HOME}/prompts"  "prompts"

    if ! $SKIP_SKILLS_CODEX; then
        install_dir  "${SCRIPT_DIR}/.codex/skills"   "${AGENTS_HOME}/skills"  "skills (-> ~/.agents/)"
    else
        info "Skipping Codex skills (--skip-skills-codex)"
    fi

    if ! $SKIP_CONFIG; then
        if $AZURE; then
            if $PERSONAL; then
                install_config_file "${SCRIPT_DIR}/.codex/config/azure/config.toml" "${CODEX_HOME}/config.toml" "config.toml (azure, personal)"
            else
                install_config_file "${SCRIPT_DIR}/.codex/config/azure/config.toml.default" "${CODEX_HOME}/config.toml" "config.toml (azure, default)"
            fi
        else
            if $PERSONAL; then
                install_config_file "${SCRIPT_DIR}/.codex/config.toml" "${CODEX_HOME}/config.toml" "config.toml (personal)"
            else
                install_config_file "${SCRIPT_DIR}/.codex/config.toml.default" "${CODEX_HOME}/config.toml" "config.toml (default)"
            fi
        fi
        if $PERSONAL; then
            install_config_file "${SCRIPT_DIR}/.codex/hooks.json" "${CODEX_HOME}/hooks.json" "hooks.json (personal)"
        else
            install_config_file "${SCRIPT_DIR}/.codex/hooks.json.default" "${CODEX_HOME}/hooks.json" "hooks.json (default)"
        fi
    else
        info "Skipping config.toml and hooks.json (--skip-config)"
    fi

    install_file "${SCRIPT_DIR}/AGENTS.md"        "${CODEX_HOME}/AGENTS.md" "AGENTS.md"
    echo ""
fi

# --- Manifest rebuild ---
# Keep old entries for destinations this run did not touch (e.g. a --claude-only
# run must not orphan the codex side), replace entries for destinations it did.
if ! $DRY_RUN && [[ -s "$MANIFEST_DESTS" ]]; then
    {
        if [[ -f "$MANIFEST_FILE" ]]; then
            awk 'FNR == NR { d[$0]; next }
                 { for (x in d) if (index($0, x "/") == 1) next; print }' \
                "$MANIFEST_DESTS" "$MANIFEST_FILE"
        fi
        cat "$MANIFEST_NEW"
    } | sort -u > "${MANIFEST_FILE}.tmp" && mv "${MANIFEST_FILE}.tmp" "$MANIFEST_FILE"
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
        echo "  Skills:      ${AGENTS_HOME}/skills/"
    fi
fi

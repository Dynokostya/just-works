#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Same variables Claude Code and Codex read, so a second profile (~/.claude-2) can be targeted
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-${HOME}/.claude}"
CODEX_HOME="${CODEX_HOME:-${HOME}/.codex}"
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

Install just-works agents, skills, and settings globally.

Options:
  --personal      Use opinionated settings (permissions, hooks, sounds)
                  Default: minimal *.default configs
  --azure         Use Azure OpenAI config instead of direct OpenAI API
  --skip-config      Skip installing settings/config files (still migrates a legacy rtk hook)
  --skip-statusline  Skip installing statusline-command.sh
  --skip-skills-claude  Skip installing Claude Code skills
  --skip-skills-codex   Skip installing Codex skills
  --claude-only   Install only Claude Code files (~/.claude/)
  --codex-only    Install only Codex files (~/.codex/, ~/.agents/)
  --dry-run       Show what would be installed without making changes
  --no-backup     Skip backup prompt, disable backups (for CI/non-interactive)
  -h, --help      Show this help message

Environment:
  CLAUDE_CONFIG_DIR  Claude Code config dir to install into (default ~/.claude)
  CODEX_HOME         Codex home to install into (default ~/.codex)

What gets installed:
  ~/.claude/
    agents/       Agent definitions (python-code-writer, prompt-writer, ...)
    skills/       Coding and prompting standards
    output-styles/  Selectable output styles (compressed, ...)
    settings.json             Permission and hook configuration
    CLAUDE.md                 Global behavioral instructions
    web-chat-prompt.md        Instructions for claude.ai chat
    statusline-command.sh     Status line script (needs jq)
    hooks/skill-guard.sh      Loads coding skills before the first code edit (needs jq)

  ~/.codex/
    agents/       Custom agent definitions (python-code-writer, prompt-writer, ...)
    config.toml   Codex CLI configuration (--azure for Azure OpenAI)
    hooks.json    Lifecycle hooks (notification)
    AGENTS.md     Global behavioral instructions

  ~/.agents/
    skills/       Coding and prompting standards (Codex discovery path)

Agents, skills and output styles are installed one entry at
a time. Other files in those directories are never touched. Each home keeps a
.just-works-manifest listing the entries it installed; entries that a later
version no longer ships are removed (after a backup, unless --no-backup).
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
        -h|--help)     usage ;;
        *) error "Unknown option: $1"; usage ;;
    esac
done

if $CLAUDE_ONLY && $CODEX_ONLY; then
    error "--claude-only and --codex-only are mutually exclusive"
    exit 1
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

# Backup a file, directory or symlink to ~/just-works-backups/<datetime>/
backup_target() {
    local target="$1"
    [[ -e "$target" || -L "$target" ]] || return 0
    local rel_path="${target#"$HOME"/}"
    local backup_path="${BACKUP_DIR}/${rel_path}"
    if $DRY_RUN; then
        warn "Would back up: $target -> $backup_path"
    else
        mkdir -p "$(dirname "$backup_path")"
        cp -RP "$target" "$backup_path"
        warn "Backed up: $target -> $backup_path"
    fi
}

# Drop caches that must never be installed
clean_junk() {
    find "$1" \( -name __pycache__ -o -name .DS_Store \) -prune -exec rm -rf {} + 2>/dev/null || true
}

# Names of the entries directly inside a source directory
list_entries() {
    ls -A "$1" | grep -v -x -e .DS_Store -e __pycache__ -e .gitkeep | sort || true
}

# Install one entry (a file or a whole skill/agent directory) at its destination.
# Only the entry itself is replaced: a directory entry is replaced as a whole so
# files removed upstream do not linger, and nothing next to it is touched.
install_entry() {
    local src="$1" dest="$2"
    if $DRY_RUN; then
        if [[ -e "$dest" || -L "$dest" ]]; then
            backup_target_if_enabled "$dest"
            warn "Would replace: $dest"
        fi
        return 0
    fi
    backup_target_if_enabled "$dest"
    mkdir -p "$(dirname "$dest")"
    # rm -rf on a symlink removes the link, not the directory it points to
    rm -rf "$dest"
    cp -R "$src" "$dest"
    [[ -d "$dest" ]] && clean_junk "$dest"
    return 0
}

backup_target_if_enabled() {
    if $DO_BACKUP; then backup_target "$1"; fi
    return 0
}

install_file() {
    local src="$1" dest="$2" label="$3"
    if [[ ! -f "$src" ]]; then
        warn "Source not found, skipping: $src"
        return
    fi
    if $DRY_RUN; then
        backup_target_if_enabled "$dest"
        info "Would copy: $src -> $dest"
    else
        backup_target_if_enabled "$dest"
        mkdir -p "$(dirname "$dest")"
        rm -f "$dest"
        cp "$src" "$dest"
        info "Installed: $label -> $dest"
    fi
}

# --- Manifest: which entries just-works installed into a home directory ---
# Used to remove entries that a later version renamed or deleted, without ever
# touching files the user (or another tool) put in the same directories.

MANIFEST_NAME=".just-works-manifest"
CUR_HOME="" CUR_MANIFEST="" OLD_ENTRIES="" NEW_ENTRIES="" DONE_SCOPES=""

# Entries shipped by earlier versions, used when a home has no manifest yet
legacy_entries() {
    case "$1" in
        claude) printf '%s\n' skills/opus-5-prompting skills/fable-5-prompting skills/gpt-5-6-prompting CLAUDE-CHAT.md agents/diagrammer.md agents/ticket-creator.md commands/git-sync.md commands/project-docs.md ;;
        codex)  printf '%s\n' agents/diagrammer.toml agents/ticket-creator.toml prompts/git-sync.md prompts/project-docs.md ;;
        agents) printf '%s\n' skills/opus-5-prompting skills/fable-5-prompting skills/gpt-5-6-prompting ;;
    esac
}

# scope_of skills/foo -> skills ; scope_of CLAUDE-CHAT.md -> .
scope_of() {
    case "$1" in
        */*) echo "${1%%/*}" ;;
        *)   echo "." ;;
    esac
}

# manifest_begin <home-dir> <legacy-key>
manifest_begin() {
    CUR_HOME="$1" CUR_MANIFEST="$1/$MANIFEST_NAME" NEW_ENTRIES="" DONE_SCOPES=""
    local raw entry
    if [[ -f "$CUR_MANIFEST" ]]; then
        raw="$(grep -v '^[[:space:]]*#' "$CUR_MANIFEST" | grep -v '^[[:space:]]*$' || true)"
    else
        raw="$(legacy_entries "$2")"
    fi
    OLD_ENTRIES=""
    while IFS= read -r entry; do
        [[ -n "$entry" ]] || continue
        if entry_is_safe "$entry"; then
            OLD_ENTRIES="${OLD_ENTRIES}${entry}"$'\n'
        else
            warn "Ignoring unsafe manifest entry: $entry"
        fi
    done <<< "$raw"
}

manifest_add() {
    NEW_ENTRIES="${NEW_ENTRIES}${1}"$'\n'
}

# A manifest line must stay inside the home directory
entry_is_safe() {
    case "$1" in
        ""|/*|.|..|../*|*/..|*/../*|*//*) return 1 ;;
    esac
    return 0
}

# prune_stale <scope> <shipped-names>: remove entries of this scope that an earlier
# install owned but the current version no longer ships.
prune_stale() {
    local scope="$1" shipped="$2" entry name target
    while IFS= read -r entry; do
        [[ -n "$entry" ]] || continue
        [[ "$(scope_of "$entry")" == "$scope" ]] || continue
        name="${entry#*/}"
        [[ "$scope" == "." ]] && name="$entry"
        if printf '%s\n' "$shipped" | grep -qxF -- "$name"; then continue; fi
        target="${CUR_HOME}/${entry}"
        [[ -e "$target" || -L "$target" ]] || continue
        if $DRY_RUN; then
            backup_target_if_enabled "$target"
            warn "Would prune (no longer shipped): $target"
        else
            backup_target_if_enabled "$target"
            rm -rf "$target"
            warn "Pruned (no longer shipped): $target"
        fi
    done <<< "$OLD_ENTRIES"
}

# sync_scope <scope> <src-dir> [label]: install every entry of src-dir into
# <home>/<scope>/ and prune entries this tool owned before but no longer ships.
# scope "." means files directly in the home directory.
sync_scope() {
    local scope="$1" src="$2" label="${3:-$1}" shipped name count=0 destdir
    if [[ ! -d "$src" ]]; then
        warn "Source not found, skipping: $src"
        return
    fi
    shipped="$(list_entries "$src")"
    prune_stale "$scope" "$shipped"
    DONE_SCOPES="${DONE_SCOPES} ${scope} "
    destdir="${CUR_HOME}/${scope}"
    while IFS= read -r name; do
        [[ -n "$name" ]] || continue
        install_entry "${src}/${name}" "${destdir}/${name}"
        manifest_add "${scope}/${name}"
        count=$((count + 1))
    done <<< "$shipped"
    if $DRY_RUN; then
        info "Would install: ${count} ${label} entries -> ${destdir}/"
    else
        info "Installed: ${count} ${label} entries -> ${destdir}/"
    fi
}

# retire_scope <scope>: remove every entry of a scope that just-works no longer ships at all
retire_scope() {
    prune_stale "$1" ""
    DONE_SCOPES="${DONE_SCOPES} $1 "
}

# sync_owned_files <src-base-dir> <name>...: files owned by just-works directly in the home dir
sync_owned_files() {
    local base="$1" name shipped=""; shift
    for name in "$@"; do shipped="${shipped}${name}"$'\n'; done
    prune_stale "." "$shipped"
    DONE_SCOPES="${DONE_SCOPES} . "
    for name in "$@"; do
        if [[ ! -f "${base}/${name}" ]]; then
            warn "Source not found, skipping: ${base}/${name}"
            continue
        fi
        install_file "${base}/${name}" "${CUR_HOME}/${name}" "$name"
        manifest_add "$name"
    done
}

# Write the manifest: entries installed now, plus old entries of scopes this run skipped
manifest_end() {
    local entry scope all tmp
    all="$NEW_ENTRIES"
    while IFS= read -r entry; do
        [[ -n "$entry" ]] || continue
        scope="$(scope_of "$entry")"
        case "$DONE_SCOPES" in
            *" ${scope} "*) ;;
            *) all="${all}${entry}"$'\n' ;;
        esac
    done <<< "$OLD_ENTRIES"
    if $DRY_RUN; then
        info "Would write manifest: $CUR_MANIFEST"
        return
    fi
    mkdir -p "$CUR_HOME"
    tmp="$(mktemp)"
    {
        echo "# Entries installed by just-works, relative to this directory. Do not add your own files."
        printf '%s' "$all" | grep -v '^$' | sort -u || true
    } > "$tmp"
    mv "$tmp" "$CUR_MANIFEST"
}

# Codex skills = the Claude skills plus Codex-only extras from .codex/skills
STAGE_DIR=""
trap 'if [[ -n "$STAGE_DIR" ]]; then rm -rf "$STAGE_DIR"; fi' EXIT
stage_codex_skills() {
    STAGE_DIR="$(mktemp -d)"
    [[ -d "${SCRIPT_DIR}/.claude/skills" ]] && cp -R "${SCRIPT_DIR}/.claude/skills/." "$STAGE_DIR/"
    [[ -d "${SCRIPT_DIR}/.codex/skills" ]] && cp -R "${SCRIPT_DIR}/.codex/skills/." "$STAGE_DIR/"
    clean_junk "$STAGE_DIR"
}

# Point legacy rtk-rewrite.sh hook commands at "rtk hook claude" (rtk >= 0.37 deletes the script)
migrate_rtk_hook() {
    local file="$1" tmp
    [[ -f "$file" ]] || return 0
    tmp="$(mktemp)"
    if ! sed -E 's/("command"[[:space:]]*:[[:space:]]*)"([^"\\]|\\.)*rtk-rewrite\.sh([^"\\]|\\.)*"/\1"rtk hook claude"/g' "$file" > "$tmp"; then
        warn "Could not migrate legacy rtk hook in $file — set its command to \"rtk hook claude\" manually"
    elif ! cmp -s "$file" "$tmp"; then
        if $DO_BACKUP; then
            backup_target "$file"
        fi
        if $DRY_RUN; then
            info "Would migrate: legacy rtk hook -> rtk hook claude in $file"
        elif cat "$tmp" > "$file"; then
            info "Migrated: legacy rtk hook -> rtk hook claude in $file"
        else
            warn "Could not migrate legacy rtk hook in $file — set its command to \"rtk hook claude\" manually"
        fi
    fi
    rm -f "$tmp"
}

# --- Claude Code ---
if ! $CODEX_ONLY; then
    echo -e "${BOLD}Claude Code${NC}"
    manifest_begin "$CLAUDE_HOME" claude
    sync_scope "agents" "${SCRIPT_DIR}/.claude/agents" "agent"
    if ! $SKIP_SKILLS_CLAUDE; then
        sync_scope "skills" "${SCRIPT_DIR}/.claude/skills" "skill"
    else
        info "Skipping Claude skills (--skip-skills-claude)"
    fi
    retire_scope "commands"
    sync_scope "output-styles" "${SCRIPT_DIR}/.claude/output-styles" "output style"

    if ! $SKIP_CONFIG; then
        if $PERSONAL; then
            install_file "${SCRIPT_DIR}/.claude/settings.json" "${CLAUDE_HOME}/settings.json" "settings.json (personal)"
        else
            install_file "${SCRIPT_DIR}/.claude/settings.json.default" "${CLAUDE_HOME}/settings.json" "settings.json (default)"
        fi
    else
        info "Skipping settings.json (--skip-config)"
        migrate_rtk_hook "${CLAUDE_HOME}/settings.json"
    fi

    install_file "${SCRIPT_DIR}/CLAUDE.md" "${CLAUDE_HOME}/CLAUDE.md" "CLAUDE.md"
    install_file "${SCRIPT_DIR}/.claude/hooks/skill-guard.sh" "${CLAUDE_HOME}/hooks/skill-guard.sh" "hooks/skill-guard.sh"
    sync_owned_files "${SCRIPT_DIR}" web-chat-prompt.md
    if ! $SKIP_STATUSLINE; then
        install_file "${SCRIPT_DIR}/.claude/statusline-command.sh" "${CLAUDE_HOME}/statusline-command.sh" "statusline-command.sh"
    else
        info "Skipping statusline-command.sh (--skip-statusline)"
    fi
    manifest_end
    echo ""
fi

# --- Codex ---
if ! $CLAUDE_ONLY; then
    echo -e "${BOLD}Codex${NC}"
    manifest_begin "$CODEX_HOME" codex
    sync_scope "agents" "${SCRIPT_DIR}/.codex/agents" "agent"
    retire_scope "prompts"
    manifest_end

    if ! $SKIP_SKILLS_CODEX; then
        stage_codex_skills
        manifest_begin "$AGENTS_HOME" agents
        sync_scope "skills" "$STAGE_DIR" "skill"
        manifest_end
    else
        info "Skipping Codex skills (--skip-skills-codex)"
    fi

    if ! $SKIP_CONFIG; then
        if $AZURE; then
            if $PERSONAL; then
                install_file "${SCRIPT_DIR}/.codex/config/azure/config.toml" "${CODEX_HOME}/config.toml" "config.toml (azure, personal)"
            else
                install_file "${SCRIPT_DIR}/.codex/config/azure/config.toml.default" "${CODEX_HOME}/config.toml" "config.toml (azure, default)"
            fi
        else
            if $PERSONAL; then
                install_file "${SCRIPT_DIR}/.codex/config.toml" "${CODEX_HOME}/config.toml" "config.toml (personal)"
            else
                install_file "${SCRIPT_DIR}/.codex/config.toml.default" "${CODEX_HOME}/config.toml" "config.toml (default)"
            fi
        fi
        if $PERSONAL; then
            install_file "${SCRIPT_DIR}/.codex/hooks.json" "${CODEX_HOME}/hooks.json" "hooks.json (personal)"
        else
            install_file "${SCRIPT_DIR}/.codex/hooks.json.default" "${CODEX_HOME}/hooks.json" "hooks.json (default)"
        fi
    else
        info "Skipping config.toml and hooks.json (--skip-config)"
    fi

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
        echo "  Skills:      ${AGENTS_HOME}/skills/"
    fi
fi

#!/usr/bin/env bash
set -euo pipefail

# Bootstrap for curl | bash install.
# Downloads the repo tarball to a temp dir and runs install.sh.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/dynokostya/just-works/main/bootstrap.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/dynokostya/just-works/main/bootstrap.sh | bash -s -- --personal
#   JUST_WORKS_REF=v1.1.3 curl -fsSL https://.../bootstrap.sh | bash   # pin to a tag

REPO="${JUST_WORKS_REPO:-dynokostya/just-works}"
REF="${JUST_WORKS_REF:-main}"

if [[ -t 1 ]]; then
    GREEN='\033[0;32m' RED='\033[0;31m' BOLD='\033[1m' NC='\033[0m'
else
    GREEN='' RED='' BOLD='' NC=''
fi

info()  { echo -e "${GREEN}[+]${NC} $*"; }
error() { echo -e "${RED}[x]${NC} $*" >&2; }

for cmd in curl tar; do
    if ! command -v "$cmd" &>/dev/null; then
        error "$cmd is required but not installed"
        exit 1
    fi
done

TMP_DIR="$(mktemp -d -t just-works.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo -e "${BOLD}just-works bootstrap${NC}"
info "Downloading ${REPO}@${REF}..."

TARBALL_URL="https://codeload.github.com/${REPO}/tar.gz/${REF}"
if ! curl -fsSL "$TARBALL_URL" | tar xz -C "$TMP_DIR"; then
    error "Failed to download or extract ${TARBALL_URL}"
    exit 1
fi

INSTALL_DIR="$(find "$TMP_DIR" -maxdepth 1 -mindepth 1 -type d | head -1)"
if [[ -z "$INSTALL_DIR" || ! -f "${INSTALL_DIR}/install.sh" ]]; then
    error "install.sh not found in extracted archive"
    exit 1
fi

info "Running installer..."
echo ""
exec bash "${INSTALL_DIR}/install.sh" "$@"

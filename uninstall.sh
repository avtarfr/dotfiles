#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Rollback / Uninstaller
# Cleanly removes dotfiles symlinks and restores previous configurations
# ==============================================================================

set -euo pipefail

BOLD="\033[1m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

log_info()    { echo -e "${CYAN}[INFO]${RESET} $1"; }
log_success() { echo -e "${GREEN}[OK]${RESET} $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${RESET} $1"; }
log_error()   { echo -e "${RED}[ERROR]${RESET} $1"; }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BOLD}${YELLOW}==============================================================================${RESET}"
echo -e "${BOLD}                        Dotfiles Rollback / Uninstaller                       ${RESET}"
echo -e "${BOLD}${YELLOW}==============================================================================${RESET}"
echo ""


# Locate backup directory (command line argument has highest priority)
BACKUP_DIR="${1:-}"

if [ -f "$HOME/.dotfiles_last_backup" ]; then
    BACKUP_DIR="$(cat "$HOME/.dotfiles_last_backup")"
fi

if [ -z "$BACKUP_DIR" ] || [ ! -d "$BACKUP_DIR" ]; then
    LATEST_BACKUP=$(find "$HOME" -maxdepth 1 -type d -name ".dotfiles_backup_*" 2>/dev/null | sort | tail -n1 || true)
    if [ -n "$LATEST_BACKUP" ] && [ -d "$LATEST_BACKUP" ]; then
        BACKUP_DIR="$LATEST_BACKUP"
    fi
fi

if [ -z "$BACKUP_DIR" ] || [ ! -d "$BACKUP_DIR" ]; then
    log_error "No backup directory found in $HOME. Nothing to restore automatically."
    exit 1
fi

log_info "Identified backup directory: $BACKUP_DIR"
read -rp "Are you sure you want to remove dotfiles symlinks and restore this backup? [y/N]: " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    log_warn "Rollback cancelled."
    exit 0
fi

# 1. Remove Stow symlinks
log_info "Removing dotfiles symlinks via GNU Stow..."
if command -v stow &>/dev/null; then
    stow -d "$DOTFILES_DIR" -t "$HOME" -D . 2>/dev/null || true
fi

# Clean any lingering symlinks pointing to this repo
for item in "$DOTFILES_DIR"/.config/*; do
    name="$(basename "$item")"
    target="$HOME/.config/$name"
    if [ -L "$target" ]; then
        rm -rf "$target"
    fi
done

for script in "$DOTFILES_DIR"/.local/bin/*; do
    name="$(basename "$script")"
    target="$HOME/.local/bin/$name"
    if [ -L "$target" ]; then
        rm -f "$target"
    fi
done

for dot in .gitconfig .gtkrc-2.0; do
    if [ -L "$HOME/$dot" ]; then
        rm -f "$HOME/$dot"
    fi
done

# 2. Restore backed-up configurations
log_info "Restoring previous configurations from $BACKUP_DIR..."
for item in "$BACKUP_DIR"/*; do
    [ -e "$item" ] || continue
    name="$(basename "$item")"
    if [ "$name" == ".local" ]; then
        if [ -d "$BACKUP_DIR/.local/bin" ]; then
            mkdir -p "$HOME/.local/bin"
            cp -r "$BACKUP_DIR/.local/bin/"* "$HOME/.local/bin/" 2>/dev/null || true
        fi
    else
        cp -r "$item" "$HOME/.config/"
    fi
done

rm -f "$HOME/.dotfiles_last_backup"
log_success "Previous configurations restored successfully."
echo ""
echo -e "${BOLD}${GREEN}==============================================================================${RESET}"
echo -e "${BOLD}${GREEN}  Rollback Complete! Your previous desktop configuration is restored.         ${RESET}"
echo -e "${BOLD}${GREEN}==============================================================================${RESET}"

#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Installer & System Bootstrapper
# Base: EndeavourOS / Arch Linux
# Upstream Base: Fork & adoption of End-4 Hyprland (illogical-impulse)
# ==============================================================================

set -euo pipefail

# Visual formatting
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

# Support --restore or -r flags to trigger rollback
if [[ "${1:-}" == "--restore" ]] || [[ "${1:-}" == "-r" ]]; then
    exec "/uninstall.sh" "${@:2}"
fi

BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

echo -e "${BOLD}${CYAN}==============================================================================${RESET}"
echo -e "${BOLD}       Hyprland Dotfiles Bootstrapper (End-4 / illogical-impulse Base)        ${RESET}"
echo -e "${BOLD}${CYAN}==============================================================================${RESET}"
echo ""

# 1. Distribution Check
if [ ! -f /etc/arch-release ]; then
    log_error "This installation script is designed for Arch Linux / EndeavourOS."
    exit 1
fi
log_success "Arch Linux base detected."

# 2. Check for yay
if ! command -v yay &>/dev/null; then
    log_warn "AUR helper 'yay' was not found."
    read -rp "Would you like to install 'yay' now? [y/N]: " install_yay
    if [[ "$install_yay" =~ ^[Yy]$ ]]; then
        sudo pacman -S --needed --noconfirm base-devel git
        TMP_YAY=$(mktemp -d)
        git clone https://aur.archlinux.org/yay.git "$TMP_YAY"
        (cd "$TMP_YAY" && makepkg -si --noconfirm)
        rm -rf "$TMP_YAY"
        log_success "Installed yay successfully."
    else
        log_error "yay is required to install desktop packages. Aborting."
        exit 1
    fi
fi

# 3. Ensure GNU Stow is installed
if ! command -v stow &>/dev/null; then
    log_info "Installing GNU Stow for symlink management..."
    sudo pacman -S --needed --noconfirm stow
fi

# 4. Package Installation
if [ -f "$DOTFILES_DIR/packages/pacman.txt" ]; then
    read -rp "Install native pacman packages? [y/N]: " install_native
    if [[ "$install_native" =~ ^[Yy]$ ]]; then
        log_info "Installing native packages via pacman..."
        sudo pacman -S --needed --noconfirm - < "$DOTFILES_DIR/packages/pacman.txt"
        log_success "Native packages installed."
    fi
fi

if [ -f "$DOTFILES_DIR/packages/aur.txt" ]; then
    read -rp "Install AUR packages via yay? [y/N]: " install_aur
    if [[ "$install_aur" =~ ^[Yy]$ ]]; then
        log_info "Installing AUR packages via yay..."
        yay -S --needed --noconfirm - < "$DOTFILES_DIR/packages/aur.txt"
        log_success "AUR packages installed."
    fi
fi

# 5. Backup Conflicting Configs
log_info "Checking for existing configurations to back up..."
mkdir -p "$BACKUP_DIR"
backed_up=0

for item in "$DOTFILES_DIR"/.config/*; do
    name="$(basename "$item")"
    target="$HOME/.config/$name"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        cp -r "$target" "$BACKUP_DIR/"
        rm -rf "$target"
        backed_up=1
    fi
done

for script in "$DOTFILES_DIR"/.local/bin/*; do
    name="$(basename "$script")"
    target="$HOME/.local/bin/$name"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        mkdir -p "$BACKUP_DIR/.local/bin"
        cp "$target" "$BACKUP_DIR/.local/bin/"
        rm -f "$target"
        backed_up=1
    fi
done

if [ "$backed_up" -eq 1 ]; then
    echo "$BACKUP_DIR" > "$HOME/.dotfiles_last_backup"
    log_success "Existing conflicting configs safely backed up to $BACKUP_DIR"
    log_info "To revert at any time, run: ./uninstall.sh"
else
    rm -rf "$BACKUP_DIR"
fi

# 6. Deploy Configurations via Stow
log_info "Deploying dotfiles to $HOME via GNU Stow..."
mkdir -p "$HOME/.config" "$HOME/.local/bin"

# Symlink all configs and scripts
stow -d "$DOTFILES_DIR" -t "$HOME" --adopt .
# Restore dotfiles repo state if adopt made changes
git -C "$DOTFILES_DIR" checkout -- . 2>/dev/null || true
log_success "Dotfiles deployed successfully."


# 7. Hyprpm Plugins (scrolloverview for Win+Tab & gestures)
if command -v hyprpm &>/dev/null; then
    log_info "Setting up scrolloverview plugin via hyprpm (needed for Win+Tab)..."
    hyprpm update 2>/dev/null || true
    if ! hyprpm list 2>/dev/null | grep -q "scrolloverview"; then
        hyprpm add https://github.com/yayuuu/hyprland-scroll-overview 2>/dev/null || true
        hyprpm enable scrolloverview 2>/dev/null || true
    fi
    log_success "scrolloverview plugin configured for hyprpm."
fi

# 8. Monitor Configuration Setup
if [ -f "$BACKUP_DIR/hypr/custom/monitors.lua" ]; then
    log_info "Preserving existing monitors.lua layout from your previous setup..."
    cp "$BACKUP_DIR/hypr/custom/monitors.lua" "$HOME/.config/hypr/custom/monitors.lua"
    log_success "Restored existing monitor layout."
elif [ ! -f "$HOME/.config/hypr/custom/monitors.lua" ]; then
    log_info "Creating default monitors.lua from template..."
    cp "$DOTFILES_DIR/.config/hypr/custom/monitors.lua.example" "$HOME/.config/hypr/custom/monitors.lua"
    log_success "Created ~/.config/hypr/custom/monitors.lua (edit this to configure your display layout)."
fi

# 9. Git Personal Configuration
if [ ! -f "$HOME/.gitconfig.local" ]; then
    log_info "Creating ~/.gitconfig.local template..."
    cat << 'GIT_EOF' > "$HOME/.gitconfig.local"
[user]
    name = Your Name
    email = your.email@example.com
GIT_EOF
    log_success "Created ~/.gitconfig.local. Update it with your Git identity."
fi

# 10. Caffeinate Lock Personal Configuration
if [ ! -f "$HOME/.config/caffeinate-lock.conf" ]; then
    log_info "Creating ~/.config/caffeinate-lock.conf from template..."
    cp "$DOTFILES_DIR/.config/caffeinate-lock.conf.example" "$HOME/.config/caffeinate-lock.conf"
    log_success "Created ~/.config/caffeinate-lock.conf (edit this to customize your secret unlock chord)."
fi

# 11. Create Standard User Directories

mkdir -p "$HOME/Pictures/Screenshots" "$HOME/Pictures/wallpapers" "$HOME/Videos/Recordings" "$HOME/Documents" "$HOME/Projects"
log_success "Verified user directories."

# 11. Enable Essential Systemd Services
read -rp "Enable essential desktop systemd services (sddm, bluetooth, NetworkManager)? [y/N]: " enable_services
if [[ "$enable_services" =~ ^[Yy]$ ]]; then
    sudo systemctl enable --now sddm.service 2>/dev/null || true
    sudo systemctl enable --now bluetooth.service 2>/dev/null || true
    sudo systemctl enable --now NetworkManager.service 2>/dev/null || true
    log_success "System services enabled."
fi

# 12. Shell Preference
if [ "$SHELL" != "/usr/bin/fish" ] && command -v fish &>/dev/null; then
    read -rp "Set fish as your default login shell? [y/N]: " set_fish
    if [[ "$set_fish" =~ ^[Yy]$ ]]; then
        chsh -s /usr/bin/fish
        log_success "Default shell set to fish."
    fi
fi

echo ""
echo -e "${BOLD}${GREEN}==============================================================================${RESET}"
echo -e "${BOLD}${GREEN}                        Installation Complete!                                ${RESET}"
echo -e "${BOLD}${GREEN}==============================================================================${RESET}"
echo -e "You can now start Hyprland by logging into SDDM or launching 'Hyprland'."
echo -e "Press ${BOLD}SUPER + H${RESET} or run ${BOLD}hypr-cheatsheet${RESET} to view all keyboard shortcuts."

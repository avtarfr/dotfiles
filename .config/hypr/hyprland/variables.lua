-- Default variables
-- Copy these to ~/.config/hypr/custom/variables.lua to make changes in a dotfiles-update-friendly manner

-- Apps
-- PULL REQUESTS ADDING MORE WILL NOT BE ACCEPTED, CONFIG FOR YOURSELF
terminal = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'foot' 'kitty -1' 'alacritty' 'wezterm' 'konsole' 'kgx' 'uxterm' 'xterm'"
fileManager = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'kitty -1 fish -c yazi' 'nautilus' 'dolphin' 'nemo' 'thunar'"
browser = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'zen-browser' 'google-chrome-stable' 'firefox' 'brave' 'chromium' 'microsoft-edge-stable' 'opera' 'librewolf'"
codeEditor = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'windsurf' 'code' 'antigravity' 'codium' 'cursor' 'zed' 'zedit' 'zeditor' 'kate' 'gnome-text-editor' 'emacs' 'command -v nvim && kitty -1 nvim' 'command -v micro && kitty -1 micro'"
officeSoftware = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'wps' 'onlyoffice-desktopeditors' 'libreoffice'"
textEditor = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'kate' 'gnome-text-editor' 'emacs'"
volumeMixer = "kitty --class=pulsemixer-modal -e pulsemixer"
settingsApp = "XDG_CURRENT_DESKTOP=gnome ~/.config/hypr/hyprland/scripts/launch_first_available.sh 'systemsettings' 'gnome-control-center' 'better-control'"
taskManager = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'kitty -1 btop --force-utf' 'gnome-system-monitor' 'plasma-systemmonitor --page-name Processes'"

workspaceGroupSize = 10

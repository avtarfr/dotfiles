# Hyprland Dotfiles

A high-performance, polished Wayland desktop environment built on **EndeavourOS / Arch Linux**, featuring dynamic Material You theming, keyboard-centric workflows, and a curated suite of lightweight TUI modals.

> [!NOTE]
> This setup is a **fork and adoption of [End-4's Hyprland dotfiles](https://github.com/end-4/dots-hyprland)** (`dots-hyprland` by **illogical-impulse**) as its upstream foundation. It extends the core Lua architecture with custom TUI modals, automated device switching, and sanitized cross-system portability.

---

## Highlights

- **Dynamic Material You Theming**: Wallpaper colors are extracted by `matugen` and live-injected across GTK, Kitty, SwayNC, Ulauncher, and Hyprland.
- **TUI-First Control Modals**: Fast, standalone modals powered by `fzf`:
  - `netcenter`: Full Wi-Fi scanning/pairing and Bluetooth management.
  - `hypr-session`: System power, reboot, sleep, and session control.
  - `battery-info`: Direct sysfs power telemetry and health analyzer.
  - `hypr-cheatsheet`: Searchable keyboard shortcut cheat sheet.
- **Advanced Screen Capture (`hypr-snip`)**:
  - Region snip, annotation editor (`swappy`), full desktop capture, active window capture, and scrolling screenshots.
  - OCR text grabber (`tesseract`) and direct Google Lens region search.
  - High-framerate screen recording (`wf-recorder`).
- **Workspace 1 Auto-Tiler**: Pressing a single key sets up an instant 4-pane system operations dashboard (`btop`, `spotify-player`, `netcenter`, `pulsemixer`).
- **Intelligent Power Management**:
  - Automatically switches display refresh rate (e.g. 144Hz on AC, 60Hz on battery).
  - Automatically pauses video wallpapers (`mpvpaper`) when windows are active on screen to draw 0% idle GPU.
- **Safe Window Closer (`Super + Q`)**:
  - Only closes windows on the *currently focused workspace*, preventing accidental destruction of off-screen background tasks.

---

## Installation (Fresh EndeavourOS / Arch)

This configuration is designed so anyone starting with a minimal, non-GUI EndeavourOS installation can bootstrap directly into this desktop.

### 1. Clone the Repository
```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 2. Run the Bootstrap Installer
```bash
chmod +x install.sh
./install.sh
```

The installer will:
1. Detect your Arch base and ensure `yay` and `stow` are present.
2. Prompt to install native packages (`packages/pacman.txt`) and AUR packages (`packages/aur.txt`).
3. Back up any conflicting existing configs to `~/.dotfiles_backup_<timestamp>`.
4. Deploy configurations cleanly into your home directory using GNU Stow.
5. Generate your initial `~/.gitconfig.local` template.
6. Enable essential system services (`sddm`, `bluetooth`, `NetworkManager`).
7. Set `fish` as your login shell.

### 3. Display / Monitor Configuration
After installation, detect your monitor name and resolution:
```bash
hyprctl monitors
```
Edit `~/.config/hypr/custom/monitors.lua` to match your display geometry:
```lua
-- Example for a 144Hz 1080p laptop display:
monitor("eDP-1, 1920x1080@144, 0x0, 1")
```

### 4. Setting Wallpapers & Themes
Drop your wallpapers into `~/Pictures/wallpapers/`.
Press **`Ctrl + Super + T`** or run:
```bash
switchwall
```
This opens the wallpaper selector, updates `hyprpaper`, and triggers `matugen` to generate matching color palettes across the entire desktop.

---

## Keybindings & Shortcuts

| Shortcut | Category | Action | Target / Binary |
| :--- | :--- | :--- | :--- |
| `Super + Return` | Apps | Launch Terminal | `kitty` |
| `Super + Space` | Apps | App Launcher | `ulauncher-toggle` |
| `Super + Period` | Apps | Emoji Picker | `floating-emote.sh` |
| `Super + E` | Apps | TUI File Manager | `kitty -e yazi` |
| `Super + Alt + E` | Apps | GUI File Manager | `nautilus --new-window` |
| `Super + W` | Apps | Web Browser | `zen-browser` (fallback to Chrome/Firefox) |
| `Super + C` | Apps | Code Editor | `code` (VS Code) |
| `Super + X` | Apps | Text Editor | `kate` |
| `Super + V` | System | Clipboard History | `nwg-clipman` / `cliphist` |
| `Super + B` | System | Battery Telemetry | `battery-info` |
| `Super + Escape` | System | Power & Session Menu | `hypr-session` |
| `Ctrl + Super + N` | System | Network & Bluetooth | `netcenter` |
| `Ctrl + Super + I` | System | Keep-Awake (Caffeine) | `keep-awake` |
| `Ctrl + Super + T` | Theming | Choose Wallpaper & Theme | `switchwall` |
| `Print` / `Super + Shift + S` | Snip | Screenshot Menu | `hypr-snip menu` |
| `Super + Shift + Print` | Snip | Region Capture to Clipboard | `hypr-snip area` |
| `Shift + Print` | Snip | Snip & Annotate | `hypr-snip edit` (`swappy`) |
| `Ctrl + Print` | Snip | Full Screen Capture | `hypr-snip full` |
| `Alt + Print` | Snip | Active Window Capture | `hypr-snip window` |
| `Super + Shift + R` | Recording | Screen Record Region | `hypr-snip record` (`wf-recorder`) |
| `Ctrl + Alt + Print` | OCR | Grab Text from Screen | `hypr-snip ocr` (`tesseract`) |
| `Super + Ctrl + L` | Search | Google Lens Screen Region | `hypr-snip lens` |
| `Super + Q` | Window | Safe Window Close | Safe close focused window |
| `Alt + Tab` / `Super + Tab` | Window | Switch Windows | `alttab.lua` switcher |
| `Super + 1..10` | Workspace | Switch Workspace | Workspace 1–10 |
| `Super + Shift + 1..10` | Workspace | Move Window to Workspace | Workspace 1–10 |
| `Media Keys` | Hardware | Volume & Brightness OSD | `swayosd-client` |

Press **`hypr-cheatsheet`** anytime in a terminal to search and filter all active keybindings.

---

## Upstream & Acknowledgements

- **Base Architecture & Widgets**: [End-4](https://github.com/end-4) — [dots-hyprland](https://github.com/end-4/dots-hyprland)
- **Hyprland Compositor**: [Vaxry](https://github.com/vaxerski)
- **Dynamic Theming**: [InioX / Matugen](https://github.com/InioX/matugen)

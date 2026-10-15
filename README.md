# Hyprland Dotfiles

A high-performance, keyboard-centric Wayland desktop environment for **EndeavourOS / Arch Linux**, featuring an **infinite horizontal canvas** layout, dynamic Material You theming, and a curated suite of lightweight TUI modals.

> [!NOTE]
> This setup is a **fork and adoption of [End-4's Hyprland dotfiles](https://github.com/end-4/dots-hyprland)** (`dots-hyprland` by **illogical-impulse**) as its upstream foundation. It significantly extends the environment with custom TUI modals, automated device switching, seamless uninstallation/rollback, and sanitized cross-system portability.

---

## 🌟 The Flagship Feature: The Infinite Desktop Canvas

The defining highlight of this configuration is the combination of **`scrolldwindle`**, **`edgescroll`**, and **`scrolloverview`**, which transforms standard tiling into an **infinite, multi-page horizontal tape** across your workspaces.

```text
                  ◄─── Horizontal Infinite Tape ───►
┌────────────────┬────────────────┬────────────────┬────────────────┐
│     Page 1     │     Page 2     │  Active Page   │     Page 4     │
│ [Code Editor]  │ [Browser / Ref]│ [Terminal Grid]│ [Dashboard]    │
└────────────────┴────────────────┴────────────────┴────────────────┘
        ▲                                                  ▲
        └────── Navigate seamlessly with edges & keys ─────┘
```

### 1. `scrolldwindle`: Paged Dwindle Layout Engine
- Instead of shrinking windows into tiny, unusable columns when you open several applications, `scrolldwindle` arranges windows into **distinct horizontal pages** on an infinite tape.
- Keep your windows large, readable, and full-sized while cycling horizontally without cluttering your screen.
- Move between pages instantly with **`Super + Left / Right`**, move windows between pages with **`Super + Shift + Left / Right`**, and expand columns with **`Super + Alt + Left / Right`**.

### 2. `edgescroll`: Dwell-Based Display Edge Scrolling
- Physics-based screen border navigation: pushing your mouse cursor deliberately against the physical left or right display border for >300ms smoothly scrolls the canvas tape to the next page.
- Pushing against the top or bottom screen edge slides between workspaces.
- Built-in jitter dampening, corner exclusion (40px deadzone), and hysteresis prevent accidental misfires while preserving fluid mouse-driven navigation.

### 3. `scrolloverview` (`Win + Tab`): Spatial Workspace Bird's-Eye View
- Press **`Win + Tab`** or **`Super + Tab`** to trigger a visual zoom-out across your entire infinite canvas powered by the `scrolloverview` plugin ([yayuuu/hyprland-scroll-overview](https://github.com/yayuuu/hyprland-scroll-overview)).
- Seamless directional navigation (`Arrow keys` or `H/J/K/L`), `Enter` to focus, and `Escape` to dismiss.
- Automatically installed and managed via `hyprpm` during `./install.sh`.

---

## 🚀 Detailed Feature Tour

### 1. TUI-First Control Center Suite
No heavy electron control centers or sluggish desktop widgets. Fast, keyboard-navigated TUI modals powered by `fzf`:

- **`netcenter` (`Ctrl + Super + N`)**:
  A complete 29 KB standalone network and connectivity control center. Scans Wi-Fi networks, handles SSID authentication, pairs Bluetooth devices, toggles airplane mode, and displays interface telemetry in an interactive modal.
- **`battery-info` (`Super + B` / `Fn + Battery`)**:
  A standalone Python utility that parses Linux sysfs (`/sys/class/power_supply/BAT*`) directly. Dispatches desktop notifications and prints formatted capacity, health, wattage discharge, and estimated charge/run time. Automatically adapts to desktop machines without throwing errors.
- **`hypr-session` (`Super + Escape`)**:
  Catppuccin-themed session controller with quick actions for Lock, Sleep, Hibernate, Reboot, Shutdown, and Logout.
- **`hypr-cheatsheet` (`hypr-cheatsheet`)**:
  Instant fuzzy-searchable cheatsheet indexing every application shortcut, window movement, workspace bind, and system action.
- **`keep-awake` (`Ctrl + Super + I`)**:
  One-shot caffeine toggle that inhibits/resumes `hypridle` with desktop status notifications.
- **`caffeinate-lock` (`Super + Alt + L` / `Ctrl + Alt + Super + U`)**:
  Headless stealth lock that inhibits lid-switch suspend and system idle via `systemd-inhibit`, disables display signal, and exclusively grabs all mouse and keyboard inputs at the kernel level (`EVIOCGRAB`). Background simulations, scripts, and downloads keep running at 100% CPU with the laptop lid closed. Wakes when your private secret chord (or PIN) is pressed. Unlock configuration is stored privately in `~/.config/caffeinate-lock.conf` (untracked by git) so your secret keybind is never exposed publicly.


---

### 2. `hypr-snip`: Screen Capture, OCR & Visual Intelligence
A comprehensive capture suite that replaces separate screenshot and recording tools with a single, unified interface:

- **Screenshot Modes**:
  - `Print` / `Super + Shift + S`: Interactive modal to choose your capture mode.
  - `Super + Shift + Print` / `Super + Shift + A`: Direct region selection to clipboard and file.
  - `Alt + Print`: Active window capture.
  - `Ctrl + Print`: Full multi-monitor desktop capture.
  - `Super + Alt + Print`: Scrolling capture for long web pages and documents.
- **Annotation (`Shift + Print` / `Super + Shift + E`)**:
  Captures a region and immediately opens it in `swappy` for drawing arrows, blurring sensitive text, and cropping.
- **Instant OCR Text Grabber (`Ctrl + Alt + Print` / `Super + Shift + T`)**:
  Select any area containing text on screen; `tesseract` extracts the text and deposits it into your clipboard with a desktop toast.
- **Google Lens Search (`Super + Ctrl + L`)**:
  Snip any error message, photo, or diagram on screen to immediately perform a reverse image search on Google Lens.
- **High-Framerate Screen Recording (`Super + Shift + R`)**:
  Toggle lightweight region video recording powered by `wf-recorder`, saving directly to `~/Videos/Recordings/`.

---

### 3. Dynamic Material You Theming Engine
- Powered by `matugen`, your entire desktop automatically adapts its color scheme whenever you change wallpapers.
- Press **`Ctrl + Super + T`** or run `switchwall` to pick any image or video wallpaper from `~/Pictures/wallpapers/`.
- Colors are extracted and updated live across:
  - Hyprland window borders and accent highlights (`colors.lua`)
  - GTK 3 and GTK 4 stylesheets (`gtk.css`)
  - Kitty terminal emulator color sequences
  - SwayNC notification center (`colors.css`)
  - Ulauncher application launcher theme (`theme.css`)

---

### 4. Workspace 1 Operations Dashboard
- Run **`start-ws1-dashboard`** (or trigger it automatically on startup) to partition Workspace 1 into a dedicated 4-pane system operations layout:
  - **Top-Left**: `btop` system monitor
  - **Top-Right**: `spotify-player` TUI music controller
  - **Bottom-Left**: `netcenter` network and Bluetooth modal
  - **Bottom-Right**: `pulsemixer` audio volume and stream router

---

### 5. Intelligent Safe Window Closer (`Super + Q`)
Standard tiling window managers often close hidden windows on background workspaces if focus is misplaced. This configuration features a custom Lua close guard:
- Inspects the active window address against the **currently active workspace ID**.
- If no window is active on the current workspace, falls back to the window directly underneath your hardware mouse cursor.
- **Strict Guard**: Never destroys an off-screen window or background task on another workspace.

---

### 6. Hardware & Power Intelligence
- **Dynamic Refresh Rate Switching**:
  Monitors AC adapter status (`power-watcher.sh`). Automatically ramps the display to its maximum rate (e.g. 144Hz) when plugged into wall power, and drops to 60Hz when running on battery to maximize battery longevity.
- **Zero-GPU Video Wallpapers**:
  When using animated wallpapers (`mpvpaper`), `auto_pause_wallpaper.sh` continuously watches workspace window counts and sends `SIGSTOP` to pause playback whenever windows are visible, drawing 0% idle GPU/CPU.
- **On-Screen Display (OSD)**:
  `swayosd` integration for volume, mute, and brightness changes with sleek progress bars.

---

### 7. Native Wayland & Terminal Workflow
- **Terminal Clipboard Image Pasting (`kitty-paste-image`)**:
  Pressing `Ctrl + V` inside Kitty checks if your clipboard holds an image; if so, it automatically saves the PNG to `~/Pictures/Screenshots/` and types the file path directly into the terminal prompt using `wtype`.
- **Yazi File Chooser Portal (`termfilechooser`)**:
  When native GUI apps request a file picker dialog, `xdg-desktop-portal-termfilechooser` intercepts the request and launches `yazi` inside a Kitty window instead of a GTK file dialog.
- **Smooth Wayland Flags**:
  Ships tuned configurations for Google Chrome and VS Code (`chrome-flags.conf`, `code-oss.conf`) enabling native Wayland mode, smooth touchpad gestures, and Wayland IME support.

---

## 🛠️ Installation & Setup

### Prerequisites
- **EndeavourOS** or **Arch Linux** (clean minimal install with no desktop environment recommended).
- Internet connection.

### 1. Clone & Bootstrap
```bash
git clone https://github.com/avtarfr/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

The installer will:
1. Verify Arch base and ensure `yay` and `stow` are present.
2. Prompt to install native packages (`packages/pacman.txt`) and AUR packages (`packages/aur.txt`).
3. Automatically configure `hyprpm` and build the `scrolloverview` plugin.
4. Back up any conflicting existing configs into `~/.dotfiles_backup_<timestamp>`.
5. Deploy all configurations into `$HOME` via GNU Stow.
6. Generate a clean `~/.gitconfig.local` template for your identity.
7. Enable system services (`sddm`, `bluetooth`, `NetworkManager`).
8. Prompt to set `fish` as your default shell.

### 2. Configure Your Display
Check your connected monitor names and supported modes:
```bash
hyprctl monitors
```
Edit `~/.config/hypr/custom/monitors.lua` with your display specifications:
```lua
-- Example for a 144Hz 1080p laptop display:
monitor("eDP-1, 1920x1080@144, 0x0, 1")
```

### 3. Add Wallpapers
Drop wallpaper images or videos into `~/Pictures/wallpapers/`.
Press **`Ctrl + Super + T`** or run `switchwall` to pick an image and generate matching system colors.

---

## 🔄 Reverting / Rollback (Testing on Existing Systems)

If you or a friend are testing these dotfiles on top of an existing setup (such as **ML4W** or an existing **End-4** installation), your previous configurations are safely archived.

To completely revert and restore your previous desktop:
```bash
./install.sh --restore
```
*(Or run `./uninstall.sh` directly).*

This removes all Stow symlinks and restores your backed-up configurations into `~/.config/` and `~/.local/bin/`.

---

## ⌨️ Keyboard Shortcuts Reference

| Shortcut | Category | Action | Target / Binary |
| :--- | :--- | :--- | :--- |
| **`Win + Tab`** / `Super + Tab` | Canvas | **Visual Workspace Overview** | `scrolloverview` |
| `Super + Left / Right` | Canvas | Navigate Tape Pages | `scrolldwindle` page cycle |
| `Super + Shift + Left / Right` | Canvas | Move Window Across Pages | `scrolldwindle` window shift |
| `Super + Alt + Left / Right` | Canvas | Expand / Contract Column | `scrolldwindle` column resize |
| `Super + Return` / `Super + T` | Apps | Launch Terminal | `kitty` |
| `Super + Space` | Apps | App Launcher | `ulauncher-toggle` |
| `Super + Period` | Apps | Floating Emoji Picker | `floating-emote.sh` |
| `Super + E` | Apps | TUI File Manager | `kitty -e yazi` |
| `Super + Alt + E` | Apps | GUI File Manager | `nautilus --new-window` |
| `Super + W` | Apps | Web Browser | `zen-browser` (fallback Chrome/Firefox) |
| `Super + C` | Apps | Code Editor | `code` (VS Code) |
| `Super + X` | Apps | Text Editor | `kate` |
| `Super + V` | System | Clipboard History | `nwg-clipman` / `cliphist` |
| `Super + B` | System | Battery Telemetry | `battery-info` |
| `Super + Escape` | System | Power & Session Menu | `hypr-session` |
| `Ctrl + Super + N` | System | Network & Bluetooth Modal | `netcenter` |
| `Ctrl + Super + I` | System | Caffeine Keep-Awake Toggle | `keep-awake` |
| `Ctrl + Super + T` | Theming | Pick Wallpaper & Sync Theme | `switchwall` |
| `Print` / `Super + Shift + S` | Snip | Screenshot Action Menu | `hypr-snip menu` |
| `Super + Shift + Print` | Snip | Direct Region Screenshot | `hypr-snip area` |
| `Shift + Print` | Snip | Snip & Open Annotation Editor | `hypr-snip edit` (`swappy`) |
| `Ctrl + Print` | Snip | Capture Entire Desktop | `hypr-snip full` |
| `Alt + Print` | Snip | Capture Active Window | `hypr-snip window` |
| `Super + Alt + Print` | Snip | Scrolling Screenshot Capture | `hypr-snip scroll` |
| `Super + Shift + R` | Recording | Screen Record Region | `hypr-snip record` (`wf-recorder`) |
| `Ctrl + Alt + Print` | OCR | Extract Screen Text to Clipboard | `hypr-snip ocr` (`tesseract`) |
| `Super + Ctrl + L` | Search | Google Lens Region Search | `hypr-snip lens` |
| `Super + Q` | Window | Safe Focused Window Close | Workspace-guarded closer |
| `Alt + Tab` | Window | Cycle Active Windows | `alttab.lua` switcher |
| `Super + 1..10` | Workspace | Jump to Workspace | Workspaces 1–10 |
| `Super + Shift + 1..10` | Workspace | Send Window to Workspace | Workspaces 1–10 |
| `Media Keys` | Hardware | Volume & Brightness OSD | `swayosd-client` |

Run **`hypr-cheatsheet`** anytime in a terminal to search and filter all active shortcuts.

---

## 📜 Upstream & Acknowledgements

- **Base Architecture & Foundation**: [End-4](https://github.com/end-4) — [dots-hyprland](https://github.com/end-4/dots-hyprland) by illogical-impulse
- **Workspace Overview Plugin**: [yayuuu](https://github.com/yayuuu) — [hyprland-scroll-overview](https://github.com/yayuuu/hyprland-scroll-overview)
- **Hyprland Compositor**: [Vaxry](https://github.com/vaxerski)
- **Material You Dynamic Theming**: [InioX](https://github.com/InioX) — [matugen](https://github.com/InioX/matugen)

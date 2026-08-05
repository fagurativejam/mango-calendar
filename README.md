# 📅 Mango Calendar

A portable, sleek, and frameless desktop calendar widget built with Python and PyQt6. Designed as a native standalone companion utility for **MangoWM**, it features a fully modular architecture wrapped inside a self-contained, repeatable Nix flake ecosystem.

---

## ✨ Features

* **🪟 Desktop-Native Architecture**: Runs as a lightweight, frameless, and translucent floating widget (`BypassWindowManagerHint`).
* **🗓️ Smart Week Trackers**: Automatically displays calculated week-of-year indicators (`W01`–`W53`) down the leftmost column using a classic Sunday-start matrix layout.
* **🎨 Dynamic JSON Theme Engine**: Fully tracks and scales UI typography, custom icon button glyphs, and window coloring profiles instantly.
* **🎯 Crosshair Grid Highlighting**: Custom tracking engine that dynamically renders background translucent highlights across rows and columns on hover.
* **⚡ Dual-Mode Shell Design**: Seamless architecture combining `theme.py` and `main.py` inline via `builtins.readFile` into a lint-free script binary.
* **🛑 Instant Escape Controls**: Quick global event listeners to dismiss the calendar on `Esc`, `Q`, or an application canvas **Right-Click**.

---

## 🛠️ Tech Stack

* **Core Runtime**: Python 3
* **Graphics Toolkit**: PyQt6
* **Environment Provisioning**: Nix Flakes (NixOS Core Compatible)
* **Shell Hook Manager**: direnv

---

## 📦 Installation & Deployment

### ❄️ For Nix / NixOS Users (Declarative Setup)

You can lock this project as an input directly inside your system configuration and inject the package wrapper declaratively.

#### 1. Add the Flake Input
Append the calendar repository directly to your system's `flake.nix` input block:

```nix
inputs = {
  # ... your other inputs ...
  mango-calendar.url = "github:fagurativejam/mango-calendar";
};
```

#### 2. Inject via Home Manager
Import the compiled wrapper directly into your user package declaration profile. This resolves the correct package binary safely across any underlying target architecture (`x86_64-linux`, `aarch64-linux`, etc.):

```nix
{ pkgs, inputs, ... }:

{
  home.packages = [
    inputs.mango-calendar.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
```

#### 3. Declarative Configuration & Theming Module
You can automatically deploy your theme configuration using Home Manager by mapping your preferences into a `theme.json` file via `builtins.toJSON`. Customize the font name, size, button icons, and hex colors below to match your system aesthetics:

```nix
{ pkgs, ... }:

{
  # DECLARATIVE CONFIG GENERATION: Generates your local configuration automatically on system rebuild
  xdg.configFile."mango-calendar/theme.json".text = builtins.toJSON {
    # Typography Configuration Settings
    font_face = "JetBrainsMono Nerd Font";
    font_size = 13;

    # Custom UI Navigation Button Text Tokens (Supports Nerd Font Icons)
    buttons = {
      prev_yr = " ";
      prev_mo = " ";
      next_mo = " ";
      next_yr = " ";
    };

    # Master Color Palette Maps (Replace with your preferred hex colors)
    colors = {
      bg     = "#1e1e2e";  # Main background color
      muted  = "#585b70";  # Secondary text and grid highlights
      accent = "#cba6f7";  # Active header title and highlights
      text   = "#cdd6f4";  # Base calendar day numbers
      today  = "#f38ba8";  # Current date highlighting token
    };
  };
}
```

#### 4. Instant Ad-Hoc Execution (CLI)
Run the compiled standalone window build directly from memory without installing components system-wide:
```bash
nix run github:fagurativejam/mango-calendar
```

---

### 🐍 For Non-Nix / Standard Linux Users

If you are running a traditional distribution without the Nix package manager, you can execute the calendar directly using a standard Python virtual environment.

#### 1. System Prerequisites
Ensure your local package manager contains the core layout dependencies required for PyQt6 (e.g., on Debian/Ubuntu systems):
```bash
sudo apt update && sudo apt install python3-pip python3-venv
```

#### 2. Clone and Setup Environment
```bash
git clone https://github.com
cd mango-calendar

# Create an isolated python environment
python3 -m venv venv
source venv/bin/activate

# Install PyQt6 runtime boundaries
pip install PyQt6
```

#### 3. Run the Widget
```bash
python3 main.py
```

---

## ⌨️ Interaction Controls

| Action | Control Bindings |
| :--- | :--- |
| **Previous / Next Month** | Click `<` or `>` (Or customized glyph icons) |
| **Previous / Next Year** | Click `<<` or `>>` (Or customized glyph icons) |
| **Select Calendar Day** | Left-Click a numerical cell |
| **Exit Application** | Press `Esc`, Press `Q`, or Right-Click anywhere |

---

## 🎨 Manual Configuration Format

If not managing themes declaratively through Nix, the application fallback engine natively tracks local files located in your home configuration directory.

* **File Location**: `~/.config/mango-calendar/theme.json`

```json
{
  "font_face": "JetBrainsMono Nerd Font",
  "font_size": 13,
  "buttons": {
    "prev_yr": "<<",
    "prev_mo": "<",
    "next_mo": ">",
    "next_yr": ">>"
  },
  "colors": {
    "bg": "#1e1e2e",
    "muted": "#585b70",
    "accent": "#cba6f7",
    "text": "#cdd6f4",
    "today": "#f38ba8"
  }
}
```

---

## 🏗️ Project Structure

```text
├── .envrc           # Automated workspace loading hook mapping
├── .gitignore       # Source index build boundaries exclusion list
├── flake.nix        # Consolidated Nix system packages build manifest
├── theme.py         # Cascading QSS stylesheet compiler and parser
└── main.py          # Core Qt Application loop, grid layouts, and window properties
```

---

## 🤝 Contributing

Contributions are welcome! Please open an issue or submit a pull request if you want to add alternative layout grids, sizing flags, or additional window configuration arguments.

## 📄 License

This project is open-source software licensed under the **MIT License**.


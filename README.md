#  mango-calendar

A sleek, lightweight calendar widget built natively with the **LÖVE 2D framework** and **Lua**, explicitly optimized for floating canvas layers inside the **MangoWM** window compositor on NixOS.

Features a full month grid, interactive navigation buttons for tracking years or months, a selection state indicator, and an instant right-click dismissal handler.

---

## 🛠️ Local Development & Testing

This project leverages Nix Flakes to establish a reproducible, hermetically sealed development shell containing all necessary tooling.

To jump straight into hacking on your Lua scripts or testing changes locally, run:

```zsh
# Enter the reproducible dev shell matrix
nix develop

# Spin up your active workspace files through LÖVE instantly
love .
```

---

## 🚀 NixOS / Home Manager Integration

This repository compiles a native executable package derivation, completely wrapping your Lua source assets inside the Nix store.

### 1. Add to your Flake Inputs
Open your primary system configuration's `flake.nix` file (e.g., `~/Bullshit/flake.nix`) and add this repository to your global tracking index:

```nix
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # ... your existing inputs
    
    # Track your custom packaged calendar binary from GitHub
    mango-calendar.url = "github:your-github-username/mango-calendar";
  };
```

### 2. Inject into your User Packages
Open your user module file (e.g., `mango-figs.nix`) and drop the package derivation directly into your environment setup:

```nix
{ pkgs, inputs, ... }:

{
  home.packages = [
    # Resolves your flake input directly to the compiled system binary wrapper
    inputs.mango-calendar.packages.\${pkgs.system}.default
  ];
  
  # Ensure Mango WM isolates and floats the window geometry correctly
  wayland.windowManager.mango.settings.windowrule = [
    "isfloating:1,width:320,height:240,appid:love"
    "animation_type_open:zoom,animation_type_close:zoom,isfloating:1,appid:love"
  ];
}
```

### 3. Hook to Waybar
Open your status bar panel code (`waybar.nix`) and wire your clock's click interaction directly to your fresh system binary string:

```nix
        clock = {
          format = "{:%a %b %d %I:%M %p}";
          tooltip-format = "{:%A, %B %d, %Y — %I:%M:%S %p}";
          
          # Spawns your custom packaged flake app completely raw
          on-click = "mango-calendar";
        };
```

---

## 🎨 Centralized Dynamic Theming

To keep your widget perfectly synchronized with your central system color schema without hardcoding hex strings, let Home Manager write out a `theme.lua` configuration asset directly into your runtime paths via `home.file`.

```nix
  home.file."Projects/calendar/theme.lua".text = ''
    -- Generated automatically by Home Manager from myTheme
    local theme = {}
    theme.font_size = 22
    theme.font_face = "JetBrainsMono Nerd Font"
    theme.colors = {
       bg      = { 0.1, 0.11, 0.15, 0.95 },
       muted   = { 0.35, 0.4, 0.55, 1.0 },
       accent  = { 0.48, 0.63, 0.97, 1.0 },
       text    = { 0.8, 0.83, 0.88, 1.0 },
       today   = { 0.98, 0.46, 0.46, 0.35 }
    }
    return theme
  '';
```

---

## ⌨️ Global Shortcuts Matrix

* **`Left Click`** — Navigate months/years; select calendar grid date boxes.
* **`Right Click`** — Instantly exit/dismiss the widget window layer.
* **`Escape` / `Q`** — Cleanly abort and quit the LÖVE thread process runtime.


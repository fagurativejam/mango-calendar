import os
import json

def load_qss_theme():
    """
    Dynamically tracks centralized theme settings from any user's local path
    and returns a structured, injection-ready Qt Style Sheet (QSS) string block.
    """
    # FIXED: Dynamically expands the active user's true home path automatically
    user_home = os.path.expanduser("~")
    config_path = os.path.join(user_home, ".config", "mango-calendar", "theme.json")
    
    theme = {}
    if os.path.exists(config_path):
        try:
            with open(config_path, "r") as f:
                theme = json.load(f)
        except:
            pass

    # Generic Fallback Safety Profile (Dune / Catppuccin Style Tones)
    if not theme:
        theme = {
            "font_face": "JetBrainsMono Nerd Font",
            "font_size": 13,
            "colors": {
                "bg": "#1e1e2e",
                "muted": "#585b70",
                "accent": "#cba6f7",
                "text": "#cdd6f4",
                "today": "#f38ba8"
            }
        }

    colors = theme["colors"]
    font_face = theme["font_face"]
    font_size = theme["font_size"]

    # Compile the clean cascading application style ruleset sheet
    qss = f"""
        /* Main Application Window Canvas Backdrop Box Container */
        QWidget#MainCanvas {{
            background-color: {colors['bg']};
            border-radius: 12px;
            font-family: "{font_face}";
            font-size: {font_size}pt;
        }}

        /* Month and Year Navigation Header Strings Label */
        QLabel#HeaderTitle {{
            color: {colors['accent']};
            font-weight: bold;
            font-size: {font_size + 2}pt;
        }}

        /* Navigation Arrows Elements Row Indicators */
        QLabel#NavButton {{
            color: {colors['muted']};
            font-weight: bold;
            padding: 2px 4px;
        }}

        /* General Baseline Typography Tracker Elements */
        QLabel#CalendarLabel {{
            color: {colors['text']};
            font-weight: normal;
        }}

        /* Far-Left Column Week Indicator Labels Context */
        QLabel#WeekLabel {{
            color: {colors['muted']};
            font-weight: normal;
        }}

        /* Column Headers Labels (Su, Mo, Tu, etc.) Row Indicators */
        QLabel#DayHeaderLabel {{
            color: {colors['muted']};
            font-weight: bold;
            margin-bottom: 4px;
        }}

        /* Column Cells Marking Saturday and Sunday Numeric Grid Tokens */
        QLabel#WeekendLabel {{
            color: {colors['today']};
            font-weight: normal;
        }}

        /* Active Core Highlight Crosshair Interactive Row/Column Grid Tracks Overlay */
        QLabel#CrosshairHighlight {{
            background-color: {colors['muted']};
            border-radius: 4px;
        }}

        /* Today Active System Current Date Badge Cell Container */
        QLabel#TodayBadge {{
            background-color: {colors['today']};
            color: {colors['bg']};
            border-radius: 6px;
            font-weight: bold;
        }}

        /* Active User Clicked Selection Focus Target Destination Cell Container */
        QLabel#SelectedBadge {{
            background-color: {colors['accent']};
            color: {colors['bg']};
            border-radius: 6px;
            font-weight: bold;
        }}
    """
    return qss, theme


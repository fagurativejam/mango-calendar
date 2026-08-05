#!/usr/bin/env python3
import os
import sys
import datetime
import calendar
from PyQt6.QtCore import Qt
from PyQt6.QtWidgets import QApplication, QWidget, QVBoxLayout, QHBoxLayout, QLabel, QGridLayout, QFrame

# FIXED LOGIC: Resolves the function dynamically from memory or runtime path imports!
if "load_qss_theme" not in globals():
    theme_module = __import__("theme")
    load_qss_theme = theme_module.load_qss_theme

class HoverLabel(QLabel):
    """
    An enhanced QLabel that triggers coordinate tracking handlers on the parent canvas
    to calculate crosshair grid selections and process active date left-clicks natively.
    """
    def __init__(self, text, row, col, parent=None):
        super().__init__(text, parent)
        self.row = row
        self.col = col
        self.parent_window = parent
        self.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.setMinimumSize(42, 28)

    def enterEvent(self, event):
        if self.parent_window and hasattr(self.parent_window, "render_crosshair"):
            self.parent_window.render_crosshair(self.row, self.col)
        super().enterEvent(event)

    def leaveEvent(self, event):
        if self.parent_window and hasattr(self.parent_window, "clear_crosshair"):
            self.parent_window.clear_crosshair()
        super().leaveEvent(event)

    def mousePressEvent(self, event):
        if event.button() == Qt.MouseButton.LeftButton and self.parent_window:
            try:
                day_num = int(self.text().strip())
                self.parent_window.select_day(day_num)
            except ValueError:
                pass
        super().mousePressEvent(event)


class MangoCalendar(QWidget):
    def __init__(self):
        super().__init__()
        
        # 1. Fetch our master QSS styles and theme dictionaries
        self.qss, self.theme_dict = load_qss_theme()
        self.setStyleSheet(self.qss)

        # 2. Configure Frameless Window & Translucent Base Layout Track
        self.setWindowFlags(
            Qt.WindowType.Window | 
            Qt.WindowType.FramelessWindowHint | 
            Qt.WindowType.BypassWindowManagerHint
        )
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground, True)

        # 3. Create a Single Solid Frame Box to paint our background color
        self.base_container = QFrame(self)
        self.base_container.setObjectName("MainCanvas")
        
        # FIXED GEOMETRY BOX: Both dimensions are completely hardcoded and static now!
        self.setFixedWidth(400)
        self.setFixedHeight(300)

        # 4. Mount the Frame into the Base Window Layer
        outer_layout = QVBoxLayout(self)
        outer_layout.setContentsMargins(0, 0, 0, 0)
        outer_layout.addWidget(self.base_container)

        # 5. Core Layout Frame Container for Inner Content Elements
        self.main_layout = QVBoxLayout()
        self.main_layout.setContentsMargins(20, 20, 20, 20)
        self.base_container.setLayout(self.main_layout)

        # ==================== Header Navigation Layout ====================
        self.header_layout = QHBoxLayout()
        self.main_layout.addLayout(self.header_layout)

        # Extract customized glyph sets safely with clean text fallbacks
        btn_cfg = self.theme_dict.get("buttons", {})
        glyph_prev_yr = btn_cfg.get("prev_yr", "<<")
        glyph_prev_mo = btn_cfg.get("prev_mo", "<")
        glyph_next_mo = btn_cfg.get("next_mo", ">")
        glyph_next_yr = btn_cfg.get("next_yr", ">>")

        lbl_prev_yr = QLabel(glyph_prev_yr)
        lbl_prev_yr.setObjectName("NavButton")
        lbl_prev_yr.setCursor(Qt.CursorShape.PointingHandCursor)
        lbl_prev_yr.mousePressEvent = lambda e: self.change_date(-12)
        self.header_layout.addWidget(lbl_prev_yr)

        lbl_prev_mo = QLabel(glyph_prev_mo)
        lbl_prev_mo.setObjectName("NavButton")
        lbl_prev_mo.setCursor(Qt.CursorShape.PointingHandCursor)
        lbl_prev_mo.mousePressEvent = lambda e: self.change_date(-1)
        self.header_layout.addWidget(lbl_prev_mo)

        self.lbl_title = QLabel()
        self.lbl_title.setObjectName("HeaderTitle")
        self.lbl_title.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.header_layout.addWidget(self.lbl_title, stretch=1)

        lbl_next_mo = QLabel(glyph_next_mo)
        lbl_next_mo.setObjectName("NavButton")
        lbl_next_mo.setCursor(Qt.CursorShape.PointingHandCursor)
        lbl_next_mo.mousePressEvent = lambda e: self.change_date(1)
        self.header_layout.addWidget(lbl_next_mo)

        lbl_next_yr = QLabel(glyph_next_yr)
        lbl_next_yr.setObjectName("NavButton")
        lbl_next_yr.setCursor(Qt.CursorShape.PointingHandCursor)
        lbl_next_yr.mousePressEvent = lambda e: self.change_date(12)
        self.header_layout.addWidget(lbl_next_yr)

        # ==================== Stationary Grid Container ====================
        self.grid_layout = QGridLayout()
        self.grid_layout.setSpacing(6)
        self.main_layout.addLayout(self.grid_layout)

        # STATIC VERTICAL BALANCE SPACER: Anchored below the grid matrix to take up
        # empty space evenly on shorter 4 or 5-row months.
        self.main_layout.addStretch()

        # Initialize Active Date Matrix State values based on current clock settings
        now = datetime.datetime.now()
        self.real_day, self.real_month, self.real_year = now.day, now.month, now.year
        self.display_month, self.display_year = self.real_month, self.real_year
        self.selected_day = self.real_day

        self.active_grid_widgets = []
        self.cell_labels = {}

        self.recalculate_calendar()

    def recalculate_calendar(self):
        """Clears old day entries and populates the matrix cleanly inside the locked frame."""
        for widget in self.active_grid_widgets:
            widget.deleteLater()
        self.active_grid_widgets.clear()
        self.cell_labels.clear()

        # Update Header Title
        month_name = calendar.month_name[self.display_month]
        self.lbl_title.setText(f"{month_name} {self.display_year}")

        # Render Day headers 
        headers = ["Wk", "Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
        for col_idx, text in enumerate(headers):
            lbl = QLabel(text)
            lbl.setObjectName("DayHeaderLabel")
            lbl.setAlignment(Qt.AlignmentFlag.AlignCenter)
            self.grid_layout.addWidget(lbl, 0, col_idx)
            self.active_grid_widgets.append(lbl)

        # Generate the active month calendar arrays (Sunday-start)
        cal = calendar.Calendar(firstweekday=6)
        month_weeks = cal.monthdayscalendar(self.display_year, self.display_month)

        first_day_time = datetime.date(self.display_year, self.display_month, 1)
        start_week = int(first_day_time.strftime("%V"))
        
        if self.display_month == 1 and start_week >= 52:
            start_week = 1

        current_week = start_week
        max_weeks = len(month_weeks)

        # Populate rows dynamically
        for row_idx, week in enumerate(month_weeks):
            lbl_wk = QLabel(f"W{current_week:02d}")
            lbl_wk.setObjectName("WeekLabel")
            lbl_wk.setAlignment(Qt.AlignmentFlag.AlignCenter)
            self.grid_layout.addWidget(lbl_wk, row_idx + 1, 0)
            self.active_grid_widgets.append(lbl_wk)

            current_week += 1
            if current_week > 53 or (current_week > 52 and self.display_month == 12 and row_idx < max_weeks - 2):
                current_week = 1

            for col_idx, day in enumerate(week):
                if day == 0:
                    continue 

                is_weekend = (col_idx == 0 or col_idx == 6) # Sunday (0) and Saturday (6)
                is_today = (day == self.real_day and self.display_month == self.real_month and self.display_year == self.real_year)
                is_selected = (day == self.selected_day)

                # Instantiate cells (col_idx + 1 pushes columns right to leave column 0 open for week numbers)
                lbl_day = HoverLabel(str(day), row_idx + 1, col_idx + 1, self)

                if is_selected:
                    lbl_day.setObjectName("SelectedBadge")
                elif is_today:
                    lbl_day.setObjectName("TodayBadge")
                elif is_weekend:
                    lbl_day.setObjectName("WeekendLabel")
                else:
                    lbl_day.setObjectName("CalendarLabel")

                self.grid_layout.addWidget(lbl_day, row_idx + 1, col_idx + 1)
                self.active_grid_widgets.append(lbl_day)
                
                # Save crosshair cell indexes
                self.cell_labels[(row_idx + 1, col_idx + 1)] = (lbl_day, day, is_weekend, is_today)

    def change_date(self, amount):
        self.display_month += amount
        while self.display_month > 12:
            self.display_month -= 12
            self.display_year += 1
        while self.display_month < 1:
            self.display_month += 12
            self.display_year -= 1
        self.selected_day = 1 
        self.recalculate_calendar()

    def select_day(self, day):
        self.selected_day = day
        self.recalculate_calendar()

    def render_crosshair(self, target_row, target_col):
        """Processes crosshair styling highlighting overlays instantly across matching matrix elements."""
        for (r, c), (lbl, day, is_weekend, is_today) in self.cell_labels.items():
            if day != self.selected_day and not is_today:
                if r == target_row or c == target_col:
                    lbl.setStyleSheet(f"background-color: {self.theme_dict['colors']['muted']}47; border-radius: 4px;")

    def clear_crosshair(self):
        """Wipes crosshair formatting targets on leave events, instantly restoring base template sheets."""
        for (r, c), (lbl, day, is_weekend, is_today) in self.cell_labels.items():
            if day != self.selected_day and not is_today:
                lbl.setStyleSheet("") 

    # Global event matrix overrides for application management
    def keyPressEvent(self, event):
        if event.key() in (Qt.Key.Key_Escape, Qt.Key.Key_Q):
            self.close()

    def mousePressEvent(self, event):
        if event.button() == Qt.MouseButton.RightButton:
            self.close()

if __name__ == "__main__":
    os.environ["QT_LOGGING_RULES"] = "qt.qpa.services.warning=false"
    
    app = QApplication(sys.argv)
    app.setDesktopFileName("mango-calendar")
    
    widget = MangoCalendar()
    widget.show()
    sys.exit(app.exec())

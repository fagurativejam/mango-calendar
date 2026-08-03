-- App State Management Variables
local real_day, real_month, real_year -- Actual current calendar date
local display_month, display_year     -- Date the user is actively viewing
local selected_day                    -- Selected date state

-- ==================== Declarative Theme Resolution Engine ====================
local theme = {}
local user_home = os.getenv("HOME")
local config_path = user_home and (user_home .. "/.config/love/mango-calendar/theme.lua") or nil
local file = config_path and io.open(config_path, "r") or nil

if file then
    file:close()
    local chunk = loadfile(config_path)
    if chunk then theme = chunk() end
else
    -- Fallback Defaults (if running standalone outside of NixOS)
    theme.font_size = 22
    theme.font_data = nil -- Defaults to nil (LÖVE internal default font engine)
    theme.colors = {
        bg     = { 0.1, 0.11, 0.15, 0.95 },
        muted  = { 0.35, 0.4, 0.55, 1.0 },
        accent = { 0.48, 0.63, 0.97, 1.0 },
        text   = { 0.8, 0.83, 0.88, 1.0 },
        today  = { 0.98, 0.46, 0.46, 0.35 }
    }
end

-- Base64 Decoder to unpack the font string dynamically in memory
local function b64_decode(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d%d%d%d%d%d', function(x)
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

-- Layout Geometry Configurations
local days_header = {"Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"}
local calendar_grid = {}
local row_weeks = {} 
local font_main

-- Dynamically Evaluated Dimensions
local cell_w, cell_h, start_x, start_y, spacing_y, week_x, window_w, window_h
local max_rows = 5

-- Button Bounding Boxes
local btn_prev_yr, btn_prev_mo, btn_next_mo, btn_next_yr

local function get_days_in_month(month, year)
    local days = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
    if month == 2 and ((year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0)) then return 29 end
    return days[month]
end

local function recalculate_calendar()
    calendar_grid = {}
    row_weeks = {}
    max_rows = 5
    
    local days_in_month = get_days_in_month(display_month, display_year)
    local first_day_time = os.time({year = display_year, month = display_month, day = 1})
    local starting_weekday = tonumber(os.date("%w", first_day_time)) + 1 

    local slot = starting_weekday
    for day = 1, days_in_month do
        local row = math.ceil(slot / 7)
        local col = (slot - 1) % 7 + 1
        if row > max_rows then max_rows = row end
        table.insert(calendar_grid, {day = day, row = row, col = col})
        slot = slot + 1
    end

    local start_week = tonumber(os.date("%V", first_day_time))
    if display_month == 1 and start_week >= 52 then start_week = 1 end

    local current_week = start_week
    for r = 1, max_rows do
        row_weeks[r] = current_week
        current_week = current_week + 1
        if current_week > 53 or (current_week > 52 and display_month == 12 and r < max_rows - 1) then
            current_week = 1
        end
    end

    window_h = start_y + 24 + (max_rows * spacing_y) + 12
    love.window.setMode(window_w, window_h, { resizable = false })

    btn_prev_yr.x = 12
    btn_prev_mo.x = 12 + cell_w
    btn_next_mo.x = window_w - (12 + (cell_w * 2.2))
    btn_next_yr.x = window_w - 12 - cell_w
end

function love.load()
    local now = os.date("*t")
    real_day, real_month, real_year = now.day, now.month, now.year
    display_month, display_year, selected_day = real_month, real_year, real_day

    -- DYNAMIC FONT OVERRIDE SYSTEM: Decodes the base64 string directly into a LÖVE FileData object
    if theme.font_data then
        local raw_font_binary = b64_decode(theme.font_data)
        local file_data = love.filesystem.newFileData(raw_font_binary, "font.ttf")
        font_main = love.graphics.newFont(file_data, theme.font_size or 22)
    else
        -- If font_data is nil, cleanly use the default internal LÖVE font engine!
        font_main = love.graphics.newFont(theme.font_size or 22)
    end
    love.graphics.setFont(font_main)

    local font_w = font_main:getWidth("00")
    cell_w = math.ceil(font_w * 1.8)
    cell_h = math.ceil(font_main:getHeight() * 1.2)
    
    week_x = 15
    start_x = week_x + math.ceil(font_main:getWidth("W00 ") * 1.1)
    start_y = 60 
    spacing_y = math.ceil(cell_h * 1.15)
    window_w = start_x + (cell_w * 7) + 15

    btn_prev_yr = { x = 0, y = 16, w = cell_w, h = 30, label = "<<" }
    btn_prev_mo = { x = 0, y = 16, w = cell_w, h = 30, label = "<"  }
    btn_next_mo = { x = 0, y = 16, w = cell_w, h = 30, label = ">"  }
    btn_next_yr = { x = 0, y = 16, w = cell_w, h = 30, label = ">>" }

    recalculate_calendar()
end

function love.draw()
    local ww = love.graphics.getWidth()
    love.graphics.setColor(theme.colors.bg) 
    love.graphics.rectangle("fill", 0, 0, window_w, window_h, 12, 12)

    love.graphics.setColor(theme.colors.muted)
    local buttons = {btn_prev_yr, btn_prev_mo, btn_next_mo, btn_next_yr}
    for _, btn in ipairs(buttons) do love.graphics.printf(btn.label, font_main, btn.x, btn.y, btn.w, "center") end

    local month_str = os.date("%B %Y", os.time({year = display_year, month = display_month, day = 1}))
    love.graphics.setColor(theme.colors.accent) 
    love.graphics.printf(month_str, font_main, btn_prev_mo.x + btn_prev_mo.w, 16, btn_next_mo.x - (btn_prev_mo.x + btn_prev_mo.w), "center")

    love.graphics.setColor(theme.colors.muted)
    for idx, day_label in ipairs(days_header) do
        local x = start_x + (idx - 1) * cell_w
        love.graphics.printf(day_label, font_main, x, start_y, cell_w, "center")
    end

    love.graphics.setColor(theme.colors.muted)
    for r = 1, max_rows do
        local y = start_y + 24 + ((r - 1) * spacing_y) 
        if row_weeks[r] then love.graphics.printf(string.format("W%02d", row_weeks[r]), font_main, week_x, y + 1, start_x - week_x, "left") end
    end

    local sel_row, sel_col = nil, nil
    for _, item in ipairs(calendar_grid) do
        if item.day == selected_day then sel_row = item.row; sel_col = item.col; break end
    end

    for _, item in ipairs(calendar_grid) do
        local x = start_x + (item.col - 1) * cell_w
        local y = start_y + 24 + ((item.row - 1) * spacing_y) 
        item.w, item.h, item.x1, item.y1 = cell_w - 4, cell_h - 2, x + 2, y + 1

        if item.day ~= selected_day and (item.row == sel_row or item.col == sel_col) then
            love.graphics.setColor(theme.colors.muted, theme.colors.muted, theme.colors.muted, 0.28)
            love.graphics.rectangle("fill", item.x1, item.y1, item.w, item.h, 4, 4)
        end
        if item.day == real_day and display_month == real_month and display_year == real_year then
            love.graphics.setColor(theme.colors.today) 
            love.graphics.rectangle("fill", item.x1, item.y1, item.w, item.h, 6, 6)
        end
        if item.day == selected_day then
            love.graphics.setColor(theme.colors.accent) 
            love.graphics.rectangle("fill", item.x1, item.y1, item.w, item.h, 6, 6)
            love.graphics.setColor(theme.colors.bg)     
        else
            if item.col == 1 or item.col == 7 then love.graphics.setColor(theme.colors.today, theme.colors.today, theme.colors.today, 1.0)
            else love.graphics.setColor(theme.colors.text) end
        end
        love.graphics.printf(tostring(item.day), font_main, x, y + 1, cell_w, "center")
    end
end

local function check_collision(mx, my, btn) return mx >= btn.x and mx <= (btn.x + btn.w) and my >= btn.y and my <= (btn.y + btn.h) end
function love.mousepressed(mx, my, button)
    if button == 2 then love.event.quit() return end
    if button == 1 then 
        if check_collision(mx, my, btn_prev_yr) then display_year = display_year - 1 recalculate_calendar()
        elseif check_collision(mx, my, btn_prev_mo) then display_month = display_month - 1
            if display_month < 1 then display_month = 12; display_year = display_year - 1; end recalculate_calendar()
        elseif check_collision(mx, my, btn_next_mo) then display_month = display_month + 1
            if display_month > 12 then display_month = 1; display_year = display_year + 1; end recalculate_calendar()
        elseif check_collision(mx, my, btn_next_yr) then display_year = display_year + 1 recalculate_calendar() end
        for _, item in ipairs(calendar_grid) do
            if item.x1 and mx >= item.x1 and mx <= (item.x1 + item.w) and my >= item.y1 and my <= (item.y1 + item.h) then selected_day = item.day end
        end
    end
end
function love.keypressed(key) if key == "escape" or key == "q" then love.event.quit() end end


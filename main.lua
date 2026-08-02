-- App State Management Variables
local real_day, real_month, real_year -- Actual current calendar date
local display_month, display_year     -- Date the user is actively viewing
local selected_day                    -- Selected date state

-- ==================== Declarative Theme Resolution Engine ====================
local theme = {}

-- PORTABLE PATH RESOLUTION: Dynamically calculates the absolute target directory paths 
-- at runtime using system environment variables, ensuring zero hardcoded file paths.
local user_home = os.getenv("HOME")
local config_path = user_home and (user_home .. "/.config/love/mango-calendar/theme.lua") or nil
local file = config_path and io.open(config_path, "r") or nil

if file then
    file:close()
    -- FIXED EXECUTION: loadfile only compiles the chunk; we MUST append () to execute it 
    -- and return the native dictionary values into our theme tracking variable!
    local chunk = loadfile(config_path)
    if chunk then
        theme = chunk()
    end
else
    -- Fallback Baseline Safety Defaults (if developing standalone outside of NixOS)
    theme.font_size = 22
    theme.font_face = nil -- FIXED: Nil forces LÖVE to fall back to its internal built-in default font!
    theme.width = 320
    theme.height = 240
    theme.colors = {
        bg     = { 0.1, 0.11, 0.15, 0.95 },
        muted  = { 0.35, 0.4, 0.55, 1.0 },
        accent = { 0.48, 0.63, 0.97, 1.0 },
        text   = { 0.8, 0.83, 0.88, 1.0 },
        today  = { 0.98, 0.46, 0.46, 0.35 }
    }
end

-- Layout Geometry Configurations
local days_header = {"Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"}
local calendar_grid = {}
local font_main

-- Button Bounding Boxes (for mouse click collision detection)
local btn_prev_yr, btn_prev_mo, btn_next_mo, btn_next_yr

-- Calculate how many days are in a given month
local function get_days_in_month(month, year)
    local days = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
    if month == 2 and ((year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0)) then
        return 29
    end
    return days[month]
end

-- Recompute the calendar grid array based on active tracking variables
local function recalculate_calendar()
    calendar_grid = {}
    local days_in_month = get_days_in_month(display_month, display_year)
    local first_day_time = os.time({year = display_year, month = display_month, day = 1})
    local starting_weekday = tonumber(os.date("%w", first_day_time)) + 1 -- Sunday = 1

    local slot = starting_weekday
    for day = 1, days_in_month do
        local row = math.ceil(slot / 7)
        local col = (slot - 1) % 7 + 1
        table.insert(calendar_grid, {day = day, row = row, col = col})
        slot = slot + 1
    end
end

function love.load()
    -- Lock actual baseline current date parameters
    local now = os.date("*t")
    real_day, real_month, real_year = now.day, now.month, now.year
    
    -- Initialize viewing tracking matrix values to current system metrics
    display_month = real_month
    display_year = real_year
    selected_day = real_day 

    -- DYNAMIC DIMENSION RESOLUTION: Forces container window to respect your Nix configurations!
    if theme.width and theme.height then
        love.window.setMode(theme.width, theme.height, { resizable = false })
    end

    -- Establish bounding box dimensions for headers button actions
    btn_prev_yr = { x = 15,  y = 20, w = 30, h = 30, label = "<<" }
    btn_prev_mo = { x = 55,  y = 20, w = 30, h = 30, label = "<"  }
    btn_next_mo = { x = 255, y = 20, w = 30, h = 30, label = ">"  }
    btn_next_yr = { x = 295, y = 20, w = 30, h = 30, label = ">>" }

    -- FIXED FONT INITIALIZATION: If theme.font_face is nil, it uses the pristine internal engine font safely
    if theme.font_face then
        font_main = love.graphics.newFont(theme.font_face, theme.font_size)
    else
        font_main = love.graphics.newFont(theme.font_size)
    end
    love.graphics.setFont(font_main)
    
    recalculate_calendar()
end

function love.draw()
    -- Main structural canvas container backdrop block using evaluated values
    love.graphics.setColor(theme.colors.bg) 
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight(), 12, 12)

    -- Render Interactive Header Navigation Buttons
    love.graphics.setColor(theme.colors.muted)
    local buttons = {btn_prev_yr, btn_prev_mo, btn_next_mo, btn_next_yr}
    for _, btn in ipairs(buttons) do
        love.graphics.printf(btn.label, font_main, btn.x, btn.y, btn.w, "center")
    end

    -- Draw Main Active Month & Year Header Title Text String
    local month_str = os.date("%B %Y", os.time({year = display_year, month = display_month, day = 1}))
    love.graphics.setColor(theme.colors.accent) 
    love.graphics.printf(month_str, font_main, 90, 20, 160, "center")

    -- Matrix spatial offset parameters
    local start_x = 25
    local spacing_x = 42
    local start_y = 65
    local spacing_y = 35

    -- Render Day-Of-The-Week Text column headers strings
    love.graphics.setColor(theme.colors.muted)
    for idx, day_label in ipairs(days_header) do
        local x = start_x + (idx - 1) * spacing_x
        love.graphics.print(day_label, x, start_y)
    end

    -- Render Core Date Grid Element Instances
    for _, item in ipairs(calendar_grid) do
        local x = start_x + (item.col - 1) * spacing_x
        local y = start_y + 15 + (item.row * spacing_y)

        item.x1 = x - 6
        item.y1 = y - 2
        item.w  = 34
        item.h  = 30

        -- 1. Structural Check: Is this box cell element the actual system current day?
        if item.day == real_day and display_month == real_month and display_year == real_year then
            love.graphics.setColor(theme.colors.today) 
            love.graphics.rectangle("fill", item.x1, item.y1, item.w, item.h, 6, 6)
        end

        -- 2. Structural Check: Is this block element matching the selected_day focus target state?
        if item.day == selected_day then
            love.graphics.setColor(theme.colors.accent) 
            love.graphics.rectangle("fill", item.x1, item.y1, item.w, item.h, 6, 6)
            love.graphics.setColor(theme.colors.bg)      -- Swaps text to background color for clear readability
        else
            love.graphics.setColor(theme.colors.text)   
        end

        love.graphics.print(string.format("%2d", item.day), x, y)
    end
end

-- Internal helper evaluating mouse positioning point intercepts against custom box structures
local function check_collision(mx, my, btn)
    return mx >= btn.x and mx <= (btn.x + btn.w) and my >= btn.y and my <= (btn.y + btn.h)
end

function love.mousepressed(mx, my, button)
    if button == 2 then
        love.event.quit()
        return
    end

    if button == 1 then 
        if check_collision(mx, my, btn_prev_yr) then
            display_year = display_year - 1
            recalculate_calendar()
        elseif check_collision(mx, my, btn_prev_mo) then
            display_month = display_month - 1
            if display_month < 1 then display_month = 12; display_year = display_year - 1; end
            recalculate_calendar()
        elseif check_collision(mx, my, btn_next_mo) then
            display_month = display_month + 1
            if display_month > 12 then display_month = 1; display_year = display_year + 1; end
            recalculate_calendar()
        elseif check_collision(mx, my, btn_next_yr) then
            display_year = display_year + 1
            recalculate_calendar()
        end

        for _, item in ipairs(calendar_grid) do
            if item.x1 and mx >= item.x1 and mx <= (item.x1 + item.w) and my >= item.y1 and my <= (item.y1 + item.h) then
                selected_day = item.day
            end
        end
    end
end

function love.keypressed(key)
    if key == "escape" or key == "q" then
        love.event.quit()
    end
end


function love.conf(t)
    t.window.title = "love_calendar"
    t.window.width = 340           -- Exact pixel width
    t.window.height = 320          -- Exact pixel height
    t.window.borderless = true     -- Strips decoration handles
    t.window.resizable = false     -- Locks dimensions
    t.window.display = 1
    
    -- Request window transparency support (great for stylized desktop widgets)
    t.window.transparent = true 
    
    -- Disables standard console window popups on Windows/Linux environments
    t.modules.joystick = false
    t.modules.physics = false
end


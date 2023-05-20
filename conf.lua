function love.conf(t)
    t.identity         = nil        -- The name of the save directory (string)
    t.version          = "11.4"     -- The LÖVE version this game was made for (string)
    t.console          = false      -- Attach a console (boolean, Windows only)

    t.window.title     = "Nes Emulator" -- The window title (string)
    t.window.icon      = nil        -- Filepath to an image to use as the window's icon (string)
    t.window.width     = 900        -- The window width (number) 1920 960
    t.window.height    = 800        -- The window height (number) 1080 540

    t.window.vsync     = false      -- Enable vertical sync (boolean)
    t.window.resizable = true       -- Window can be Resized
end

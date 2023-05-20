local addressMode = require("NES.CPU.OpCodes.addressmodes")
local controller = require("NES.Controller.controller")
local selectFile = require("Emulator.UI.Emulator.selectfile")

local keyboard = {}
G_ColorOffset = 1
local function getAddressFromUser()
    -- set up the dialog box properties
    local dialogWidth = 400
    local dialogHeight = 100
    local dialogX = (love.graphics.getWidth() - dialogWidth) / 2
    local dialogY = (love.graphics.getHeight() - dialogHeight) / 2
    local prompt = "Enter a hexadecimal address:"
    local userInput = ""

    -- define a function to handle text input events
    local function handleTextinputEvent(text)
        -- check if userInput is empty and the entered text is "b"
        if userInput == "" and text == "b" then
            userInput = "0x"
        elseif text:match("[0-9a-fA-FxX]") then
            userInput = userInput .. text
        elseif text == "\b" then
            userInput = userInput:sub(1, -2)
        end
    end

    -- run the main loop until the user enters an address
    while true do
        -- process events
        love.event.pump()
        for event, arg1, arg2, arg3 in love.event.poll() do
            if event == "textinput" then
                handleTextinputEvent(arg1)
            elseif event == "keypressed" then
                if arg1 == "return" or arg1 == "kpenter" then
                    -- convert the user input to a number and return it
                    if userInput ~= "" then return tonumber(userInput) else 
                        UseBreakPoint = false
                        return 0xffff
                    end
                elseif arg1 == "backspace" then
                    userInput = userInput:sub(1, -2)
                end
            end
        end


        -- check for escape event
        if love.keyboard.isDown("escape") then
            UseBreakPoint = false
            return 0xFFFF
        end
        -- draw the dialog box
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", dialogX+5, dialogY+5, dialogWidth-10, dialogHeight-10, 5, 5)
        love.graphics.setColor(.4, .4, .4)
        love.graphics.rectangle("fill", dialogX+5, dialogY+5, dialogWidth-10, dialogHeight-10, 5, 5)
        love.graphics.setColor(0, 1, 0)
        love.graphics.printf(prompt, dialogX, dialogY + 10, dialogWidth, "center")
        love.graphics.setColor(.6, .4, .6)
        love.graphics.rectangle("fill", dialogX + 80, dialogY + 45, dialogWidth - 160, 30, 5, 5)
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", dialogX + 80, dialogY + 45, dialogWidth - 160, 30, 5, 5)
        love.graphics.printf(userInput, dialogX + 25, dialogY + 50, dialogWidth - 50, "center")
        love.graphics.present()
    end
end

-- [""] = function() end,
local escapeCounter = 0
local firstEscapeTime = nil

-- # Setup Key Pressed Values 
local keypressed = {
    ["b"] = function()
        UseBreakPoint = true
        local value = getAddressFromUser()
        if value and UseBreakPoint then print("Breakpoint Set at "..value) end
        BreakPointValue = value 
    end,
    ["."] = function() G_CPUStep = 2 end,
    [","] = function() G_CPUStep = 0 end,
    ["y"] = function()
        G_ColorOffset = G_ColorOffset + 1 -- Palette Color Changing 
        print("Pallette Color Change ", G_ColorOffset)
        if G_ColorOffset > 7 then G_ColorOffset = 0 end
    end,
    ["t"] = function()
        G_ViewMemory = G_ViewMemory + 1 -- Testing PPU vs CPU memory 
        if G_ViewMemory > 3 then
            G_ViewMemory=0
        end
        print("Cycle Debug Hex ")
    end,
    ["/"] = function() G_CPUStep = 1 end,
    ["\\"] = function() addressMode.debugPrint = not addressMode.debugPrint end,
    ["["] = function()
        debug.viewMemory = bit.band(debug.viewMemory - 0x100, 0xffff)
        print("Shift Debug Memory '-0x100'")
    end,
    ["]"] = function()
        debug.viewMemory = bit.band(debug.viewMemory + 0x100, 0xffff)
        print("Shift Debug Memory '+0x100'")
    end,
    ["o"] = function() debug.viewMemory = bit.band(debug.viewMemory - 0x1000, 0xffff)
        print("Shift Debug Memory '+0x1000'") end,
    ["p"] = function() debug.viewMemory = bit.band(debug.viewMemory + 0x1000, 0xffff)
        print("Shift Debug Memory '-0x1000'") end,
    ["space"] = function() Initialize(love.filesystem.read("Emulator/nesEmuState.txt"))
        print("Reset") end,
    ["escape"] = function()
        if escapeCounter == 0 then
            firstEscapeTime = love.timer.getTime()
            escapeCounter = 1
        elseif escapeCounter == 1 then
            local currentTime = love.timer.getTime()
            if currentTime - firstEscapeTime <= 1.5 then
                love.event.quit()
            else
                escapeCounter = 0
            end
        end
    end,
    ["n"] = function() UseSound = not UseSound
        SoundOff()
        print("Sound Mute ", not UseSound) end,
    ["1"] = function() require("Emulator.savestate").Save("1") end,
    ["2"] = function() require("Emulator.savestate").Save("2") end,
    ["3"] = function() require("Emulator.savestate").Save("3") end,
    ["7"] = function() require("Emulator.savestate").Load("7") end,
    ["8"] = function() require("Emulator.savestate").Load("8") end,
    ["9"] = function() require("Emulator.savestate").Load("9") end,
    ["="] = function() VolumeMulti = VolumeMulti + 2
        print("Volume up "..VolumeMulti) end,
    ["-"] = function() VolumeMulti = VolumeMulti - 2
        print("Volume down "..VolumeMulti)end,
    ["l"] = function() EnableDebug = not EnableDebug end,
    ["k"] = function() Profile = not Profile end,
    [""] = function() end,

}

-- # Key is Pressed Check 
function love.keypressed(key)
    selectFile.KeyboardInput(key)
    if selectFile.isPopupVisable then return end
    if keypressed[key] then
        keypressed[key]()
    end
end

local increment = 0
-- # Setup Checks for If Key is Down 
local keyIsDown = {
    ["4"] = function() print("4") end,
    ["5"] = function() print("5") end,
    ["6"] = function()
        if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then increment = increment + 1 end
        print(increment)
    end,
    ["/"] = function() if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then G_CPUStep = 1 end end,
}

-- # Update Values if Key is Down 
function keyboard.Update(dt)
    if selectFile.isPopupVisible then return end
    controller.CheckControllers()
    -- search keyIsDown for keys that are down
    for key, value in pairs(keyIsDown) do
        if love.keyboard.isDown(key) then
            value()
        end
    end
end

return keyboard
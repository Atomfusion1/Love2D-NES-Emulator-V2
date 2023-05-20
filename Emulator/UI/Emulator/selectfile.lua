local joysticks = love.joystick.getJoysticks()
local joystick1 = joysticks[1]

local selectFile = {}
selectFile.input = ""
selectFile.isPopupVisible = false
local files_per_column = 20
local popupWidth = 700
local popupHeight = 500
local scroll_offset = 0
local selected_file_index = 5
selectFile.lastInputChar = ""
local fileList = {}


local function listFilesInDirectory(directory)
    fileList = love.filesystem.getDirectoryItems(directory)
    local filtered_files = {}

    for i, file in ipairs(fileList) do
        if love.filesystem.getInfo(directory .. "/" .. file).type == "file" then
            table.insert(filtered_files, file)
        end
    end

    -- Sort the files alphabetically, ignoring case
    table.sort(filtered_files, function(a, b)
        return a:lower() < b:lower()
    end)

    fileList = filtered_files
end

listFilesInDirectory("roms")  -- Call this function once at the start

function selectFile.DrawPopup()
    if selectFile.isPopupVisible then
        local x = (love.graphics.getWidth() - popupWidth) / 2
        local y = (love.graphics.getHeight() - popupHeight) / 2
        local mx, my = love.mouse.getPosition()

        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", x, y, popupWidth, popupHeight)

        love.graphics.setColor(0, 0, 0)
        love.graphics.printf("Choose a game:", x, y + 10, popupWidth, "center")

        local files = fileList
        local file_list_start_y = y + 100
        local file_list_spacing = 20
        for i = scroll_offset + 1, math.min(scroll_offset + files_per_column, #files) do
            local file = files[i]
            local row = (i - 1 - scroll_offset) % files_per_column
            local file_x = x + 10
            local file_y = file_list_start_y + row * file_list_spacing

            -- Determine if the mouse is hovering over the file name
            if mx >= file_x and mx <= file_x + love.graphics.getFont():getWidth(file) and
                my >= file_y and my <= file_y + love.graphics.getFont():getHeight() then
                love.graphics.setColor(0.5, 0.5, 1)  -- Highlight color when mouse is over the file name
            elseif i == selected_file_index then -- Highlight the selected file
                love.graphics.setColor(1, 0.3, 0.2)
            else
                love.graphics.setColor(0, 0, 0)
            end
            love.graphics.print(file, file_x, file_y)
        end
    end
end

local function HandleFileName(typedName)
    if not selectFile.input:lower():match("%.nes$") then -- Check if the input does not end with ".nes"
        selectFile.input = selectFile.input .. ".nes" -- Append ".nes" to the input
    end
end

local  function createSaveState(table, FILE)
    print("CreateSave "..FILE)
    -- Write the save state data to a file
    local file_path = FILE
    local file = io.open(file_path, "wb")
    if file then
        file:write(table)
        file:close()
    else
        print("Failed to create save state file at " .. file_path)
    end
end

function selectFile.MousePressed(x, y, button)
    if selectFile.isPopupVisible and button == 1 then
        local files = fileList
        local popup_x = (love.graphics.getWidth() - popupWidth) / 2
        local popup_y = (love.graphics.getHeight() - popupHeight) / 2
        local file_list_start_y = popup_y + 100
        local file_list_spacing = 20

        for i = scroll_offset + 1, math.min(scroll_offset + files_per_column, #files) do
            local file = files[i]
            local row = (i - 1 - scroll_offset) % files_per_column
            local file_x = popup_x + 10
            local file_y = file_list_start_y + row * file_list_spacing
        
            if x >= file_x and x <= file_x + popupWidth and y >= file_y and y <= file_y + file_list_spacing then
                selectFile.isPopupVisible = false
                print("Selected file: " .. file)
                local new_file_path = LoveFileDir.."/Emulator/nesEmuState.txt"
                local filePath = "Roms/" .. file
                GlobalFileName = filePath
                print("SaveState: "..filePath, new_file_path)
                createSaveState(filePath , new_file_path)
                Initialize(love.filesystem.read("Emulator/nesEmuState.txt"))
                break
            end
        end
    end
end


function selectFile.WheelMoved(x, y)
    if selectFile.isPopupVisible then
        if y > 0 and scroll_offset > 0 then
            scroll_offset = scroll_offset - 4
        elseif y < 0 and scroll_offset < #fileList - files_per_column then
            scroll_offset = scroll_offset + 4
        end
    end
end

local files = fileList
local keypressed = {
    ["`"] = function()
        selectFile.isPopupVisible = not selectFile.isPopupVisible    end,
    ["up"] = function()
        selected_file_index = math.max(selected_file_index - 1, 1)
        if selected_file_index <= scroll_offset and scroll_offset > 0 then
            scroll_offset = scroll_offset - 1
        end
    end,
    ["down"] = function()
        selected_file_index = math.min(selected_file_index + 1, #files)
        if selected_file_index > scroll_offset + files_per_column and scroll_offset < #files - files_per_column then
            scroll_offset = scroll_offset + 1
        end
    end,
    ["space"] = function()
        if selected_file_index > 0 and selected_file_index <= #files then
            local file = files[selected_file_index]
            selectFile.isPopupVisible = false
            print("Selected file: " .. file)
            local new_file_path = LoveFileDir.."/Emulator/nesEmuState.txt"
            local filePath = "Roms/" .. file
            print("SaveState: "..filePath, new_file_path)
            createSaveState(filePath , new_file_path)
            Initialize(love.filesystem.read("Emulator/nesEmuState.txt"))
        end
    end,
}


function selectFile.KeyboardInput(key)
    if keypressed[key] and selectFile.isPopupVisible or key == "`" then
        keypressed[key]()
    end
end

function love.textinput(text)
    if selectFile.isPopupVisible and text ~= '`' then
        selectFile.input = selectFile.input .. text
        selectFile.lastInputChar = text:lower() -- Store the last input character in lowercase
        local files = fileList
        for i, file in ipairs(files) do
            if file:sub(1, 1):lower() == selectFile.lastInputChar then
                scroll_offset = i - 1
                selected_file_index = i -- Update the selected file index to jump the arrow selection
                break
            end
        end
    end
end

function findNextLetterIndex(files, current_index, direction)
    local current_letter = files[current_index]:sub(1, 1):lower()
    local next_index = current_index

    if direction == "next" then
        for i = current_index + 1, #files do
            if files[i]:sub(1, 1):lower() ~= current_letter then
                next_index = i
                break
            end
        end
    elseif direction == "previous" then
        for i = current_index - 1, 1, -1 do
            if files[i]:sub(1, 1):lower() ~= current_letter then
                next_index = i
                break
            end
        end
    end

    return next_index
end

-- # Setup Gamepad Pressed Values
local gamepadIsDown = {
    ["back"] = function()
            if joystick1:isGamepadDown("start") then
                selectFile.isPopupVisible = not selectFile.isPopupVisible
            end
        end,
    ["dpup"] = function()
            selected_file_index = math.max(selected_file_index - 1, 1)
            if selected_file_index <= scroll_offset and scroll_offset > 0 then
                scroll_offset = scroll_offset - 1
            end
        end,
    ["dpdown"] = function()
            selected_file_index = math.min(selected_file_index + 1, #files)
            if selected_file_index > scroll_offset + files_per_column and scroll_offset < #files - files_per_column then
                scroll_offset = scroll_offset + 1
            end
        end,
    ["start"] = function()
        if selected_file_index > 0 and selected_file_index <= #files then
            local file = files[selected_file_index]
            selectFile.isPopupVisible = false
            print("Selected file: " .. file)
            local new_file_path = LoveFileDir.."/Emulator/nesEmuState.txt"
            local filePath = "Roms/" .. file
            print("SaveState: "..filePath, new_file_path)
            createSaveState(filePath , new_file_path)
            Initialize(love.filesystem.read("Emulator/nesEmuState.txt"))
        end
    end,
    ["rightshoulder"] = function()
        local files = fileList
        selected_file_index = findNextLetterIndex(files, selected_file_index, "next")
        scroll_offset = math.max(selected_file_index - files_per_column + 1, 0)
    end,
    ["leftshoulder"] = function()
        local files = fileList
        selected_file_index = findNextLetterIndex(files, selected_file_index, "previous")
        scroll_offset = math.min(selected_file_index - 1, #files - files_per_column)
    end,
}

function love.gamepadpressed(joy, key)
    if joystick1 then
        for key, value in pairs(gamepadIsDown) do
            if joystick1:isGamepadDown(key) then
                if key == "back" then
                    value()
                    love.timer.sleep(0.25)
                    return
                else
                    if selectFile.isPopupVisible then
                        value()
                    end
                end
            end
        end
    end
end

function love.mousepressed(x, y, button, istouch)
    selectFile.MousePressed(x, y, button)
end

function love.wheelmoved(x, y)
    selectFile.WheelMoved(x, y)
end

function love.keypressed(key, scancode, isrepeat)
    selectFile.KeyboardInput(key)
end

function love.filedropped(file)
	local filename = file:getFilename()
    print(filename)
    print("TODO - Load file: " .. filename)
end

return selectFile






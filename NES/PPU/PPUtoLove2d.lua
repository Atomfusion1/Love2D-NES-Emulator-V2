local bus = require("NES.PPU.ppuBus")
local colors = require("NES.PPU.VGA_Pallette").Pallette
local colors32 = require("NES.PPU.VGA_Pallette").Pallette_32bit2
local nameTable = require("NES.PPU.ppunametable")
local OAM = require("NES.PPU.ppuOAM")
local ppuIO = require("NES.PPU.ppuIO")
local loopy = require("NES.PPU.loopy")
local cart        = require("NES.Cartridge.Cartridge")


local PPUtoLove2d = {}
PPUtoLove2d.PointerArray = {}

local band, lshift, rshift,bor = bit.band,bit.lshift,bit.rshift, bit.bor
local PPURead = bus.PPURead
local ramBuffer = {}
local ramBuffer32 = {}

--# Create Ram Buffer of the Colors in use OLD 
local function fillRamBufferWithColors()
    for i = 0x3F00, 0x3F1F do
        local value = PPURead(i) or 0x00
        if value > 0x3F then value = band(value,0x3F) end
        ramBuffer[i] = colors[value]
    end
end
--# Create Ram Buffer of the Colors in use NEW
local function fillRamBufferWithColors32()
    for i = 0x3F00, 0x3FFF do
        local value = PPURead(i)
        if value > 0x3F then value = band(value,0x3F) end
        ramBuffer32[i] = colors32[value]
    end
end

--# Draw CHR Tiles in Debug
function PPUtoLove2d.DrawCHR(array, CHRTileSet)
    fillRamBufferWithColors()

    local NumberSprites = ((band(ppuIO.CTRL, 0x20) == 0x20) and 32 or 64)
    local spriteHeight = (NumberSprites == 64) and 8 or 16
    local yOffsetMultiplier = (NumberSprites == 64) and 1 or 2
    local colorOffset = G_ColorOffset
    for nTileY = 0, (16 * yOffsetMultiplier) - 1, yOffsetMultiplier do
        for nTileX = 0, 15 do
            local nOffset = nTileY * 256 + nTileX * (spriteHeight * 2)

            for littleY = 0, spriteHeight - 1 do
                local i = CHRTileSet
                local tileAddr = i * 0x1000 + nOffset + littleY
                local tile_lsb = PPURead(tileAddr)
                local tile_msb = PPURead(tileAddr + 8)

                local x_offset = nTileX * 8
                local y_offset = nTileY * 8 * 128 + littleY * 128

                for x = 7, 0, -1 do
                    local pixel = bor(band(tile_lsb, 0x01), lshift(band(tile_msb, 0x01), 1))
                    tile_msb = rshift(tile_msb, 1)
                    tile_lsb = rshift(tile_lsb, 1)
                    local pixelIndex = 4 * (x_offset + x + y_offset)
                    Setup1DArray(0x3F00 + colorOffset * 4 + pixel, array, pixelIndex)
                end
            end
        end
    end
    return array
end

local pixelCount = 256 * 240 * 4
local ffi = require("ffi")
local screenArray = ffi.new("uint8_t[?]", pixelCount)

--# Clear Background to Background Pallette Color
function PPUtoLove2d.SetupScreenArray(ptrScreenBuffer)
    fillRamBufferWithColors32()
    for y = 0, 239 do
        for x = 0, 255 do
            ptrScreenBuffer[(y*256 + x)] = ramBuffer32[0x3f00] -- This changes lsb msb from 8 bit ~50 us
        end
    end
end

--# Draw Main Screen Helper
local function SelectAttributeValue(attributeTable, c_X, c_Y)
    local Attr_X    = c_X % 4 -- get the last 2 bits of c_X
    local Attr_Y    = c_Y % 4 -- get the last 2 bits of c_Y
    local offset    = math.floor(Attr_Y / 2) * 4
    local shift     = math.floor(Attr_X / 2) * 2
    return band(rshift(attributeTable, offset + shift), 0x03)
end
--# Draw Main Screen Helper
local function calculateTileAndAttributeAddresses(ScrollX, ScrollY, localNamespace)
    local tileAddress         = localNamespace + ScrollY * 32 + ScrollX
    local tileID              = nameTable.NameTableMirrorRead(tileAddress)
    local attributeAddress    = 0x03C0 + (rshift(ScrollY, 2)) * 8 + rshift(ScrollX, 2) + localNamespace
    local attributeByte       = nameTable.NameTableMirrorRead(attributeAddress)
    local attributeValue      = SelectAttributeValue(attributeByte, ScrollX, ScrollY)
    return tileID, attributeValue
end

--# Draw Main Screen Helper
local function drawVisibleScreenArea(courseX, courseY, fineY, fineXOffset, fineYOffset, tile_lsb, tile_msb, attributeValue, ptrScreenBuffer)
    for fineX = 7, 0, -1 do
        local screenX = courseX * 8 + fineX - fineXOffset
        local screenY = (courseY * 8 + fineY) - fineYOffset
        if screenX >= 0 and screenX < 256 and screenY >= 0 and screenY < 240 then
            local pixelPosition = (screenX + screenY * 256)
            local pixel = bor(band(tile_lsb, 0x01), lshift(band(tile_msb, 0x01), 1))
            if pixel ~= 0 then
                local colorAddress = (0x3F00 + attributeValue * 4 + pixel)
                local color32 = ramBuffer32[colorAddress]
                ptrScreenBuffer[pixelPosition] = color32
            end
        end                    
        tile_msb = rshift(tile_msb, 1)
        tile_lsb = rshift(tile_lsb, 1)
    end
end
--& Draw Main Screen 
function PPUtoLove2d.DrawMainScreen(ptrScreenBuffer)
    local ppuIRQCount = 1
    local states = loopy.ppuStates
    local startNamespaceX   = states[ppuIRQCount].namespace_x * 0x400 + states[ppuIRQCount].namespace_y * 0x800 + 0x2000
    local fineXOffset       = states[ppuIRQCount].fineOffset_x
    local fineYOffset       = states[ppuIRQCount].fineOffset_y
    local courseScrollX     = states[ppuIRQCount].offset_x
    local courseScrollY     = states[ppuIRQCount].offset_y
    local passTableBuffer   = states[ppuIRQCount].spriteTileSet
    local backgroundTable   = states[ppuIRQCount].backgroundTable
    cart.Mirror = states[ppuIRQCount+1].mirror
    local scanLine = 0
    --print("IRQ Start ".. #states, scanLine, "loaded "..ppuIRQCount)
    ppuIRQCount             = ppuIRQCount + 1
    local sprite0Set = false
    

    for courseY = -1, 29 do
        local ScrollY = courseY + courseScrollY
        local addonNamespaceY = (ScrollY >= 30) and 0x800 or 0x000
        ScrollY = (ScrollY >= 30) and (ScrollY - 30) or ScrollY

        for fineY = 0, 7 do
            scanLine = scanLine + 1
            if states[ppuIRQCount].scanLine < 241 and scanLine == states[ppuIRQCount].scanLine then
                ppuIRQCount = ppuIRQCount + 1
                --print("IRQ Count ",scanLine, "loaded "..ppuIRQCount)
                courseScrollX   = states[ppuIRQCount].offset_x
                courseScrollY   = states[ppuIRQCount].offset_y
                fineXOffset     = states[ppuIRQCount].fineOffset_x
                fineYOffset     = states[ppuIRQCount].fineOffset_y
                
                passTableBuffer = states[ppuIRQCount].spriteTileSet
                backgroundTable = states[ppuIRQCount].backgroundTable
                cart.Mirror = states[ppuIRQCount].mirror
                
                --! If im going to hack this way i need to tie it to the game 
                if states[ppuIRQCount].ppuAddress == 0x2000 then
                    startNamespaceX = 320
                elseif states[ppuIRQCount].ppuAddress == 0x2900 then -- TNMNT Hack 
                    startNamespaceX = 9697
                    --startNamespaceX = states[ppuIRQCount-1].namespace_x * 0x400 + states[ppuIRQCount-1].namespace_y * 0x800 + states[ppuIRQCount].ppuAddress - ScrollY * 33 + fineY - 10
                else
                    startNamespaceX = states[ppuIRQCount].namespace_x * 0x400 + states[ppuIRQCount].namespace_y * 0x800 + 0x2000
                end
                --print("POST " ,courseScrollX, courseScrollY, string.format("%x",loopy.postPPUAddress) , string.format("%x",startNamespaceX) ,addonNamespaceY, ScrollY, courseY, fineY)
                
            end

            for courseX = -1, 31 do
                local ScrollX = courseX + courseScrollX
                local localNamespace = startNamespaceX + addonNamespaceY
                localNamespace = (ScrollX >= 32) and (localNamespace + 0x0400) or localNamespace
                ScrollX = (ScrollX >= 32) and (ScrollX - 32) or ScrollX
                local tileID, attributeValue = calculateTileAndAttributeAddresses(ScrollX, ScrollY, localNamespace)

                local nAddress = backgroundTable * 0x1000 + tileID * 16 + fineY
                local tile_lsb = passTableBuffer[nAddress]
                local tile_msb = passTableBuffer[nAddress + 8]

                drawVisibleScreenArea(courseX, courseY, fineY, fineXOffset, fineYOffset, tile_lsb, tile_msb, attributeValue, ptrScreenBuffer)
            end
        end
    end
end


--# Draw Sprites Helper
local function getTileData(fineY, tileIndex, flipV, spriteHeight, use8x16Sprites, passSpritePattern)
    local actualFineY = (flipV and (spriteHeight - 1 - fineY) or fineY)
    local tileID = tileIndex
    local spriteTable

    if use8x16Sprites then
        spriteTable = band(tileID, 0x01) * 0x1000
        tileID = band(tileID, 0xFE)
        if actualFineY >= 8 then
            tileID = tileID + 1
            actualFineY = actualFineY - 8
        end
    else
        spriteTable = passSpritePattern * 0x1000
    end

    return actualFineY, tileID, spriteTable
end

--# Draw Sprites Helper
local function drawSpritePixels(ptrScreenBuffer, littleY, tileIndex, palette, x, flipH, flipV, spriteHeight, use8x16Sprites, tableBuffer, passSpritePattern)
    for fineY = 0, spriteHeight - 1 do
        local actualFineY, tileID , spriteTable = getTileData(fineY, tileIndex, flipV, spriteHeight, use8x16Sprites, passSpritePattern)
        local nAddress = spriteTable + tileID * 16 + actualFineY
        local tile_lsb = tableBuffer[nAddress]
        local tile_msb = tableBuffer[nAddress + 8]

        for fineX = 7, 0, -1 do
            local pixel = bor(band(tile_lsb, 0x01), lshift(band(tile_msb, 0x01), 1))
            tile_msb = rshift(tile_msb, 1)
            tile_lsb = rshift(tile_lsb, 1)
            local xIndex = x + (flipH and (7 - fineX) or fineX)
            local yIndex = ((littleY) * 256) + fineY * 256
            local pixelIndex = (xIndex + yIndex)
            if pixel ~= 0 then -- If 0 ignore it (transparent)
                Setup1DArray32(0x3F10 + palette * 4 + pixel, ptrScreenBuffer, pixelIndex)
            end
        end
    end
end
--# Draw Sprites Helper
local function getSpriteData(spriteIndex)
    return OAM[spriteIndex * 4 + 0], OAM[spriteIndex * 4 + 1], OAM[spriteIndex * 4 + 2], OAM[spriteIndex * 4 + 3]
end
local function getSpriteAttributes(attributes)
    return band(attributes, 0x03), band(attributes, 0x40) > 0, band(attributes, 0x80) > 0
end
--# Draw Sprites Helper

local function processSprite(ptrScreenBuffer, spriteIndex, spriteHeight, use8x16Sprites)
    local scanLines, tileIndex, attributes, x = getSpriteData(spriteIndex)
    if scanLines <= 1 or scanLines > 239 then
        return
    end
    local passTableBuffer = {}
    local passSpritePattern = nil
    local states = loopy.ppuStates
    local stateFound = 1
    -- Iterate through states
    for i = 1, #states-1 do
        -- Check if scanLines is between the scanLine of the current state and the next state
        if scanLines >= states[i].scanLine and scanLines < states[i + 1].scanLine then
            passTableBuffer = states[i+1].spriteTileSet
            passSpritePattern = states[i+1].spriteTable
            stateFound = i+1
            break
        end
    end
    if states[stateFound].isDrawSprites == false then return end
    local palette, flipH, flipV = getSpriteAttributes(attributes)
    drawSpritePixels(ptrScreenBuffer, scanLines, tileIndex, palette, x, flipH, flipV, spriteHeight, use8x16Sprites, passTableBuffer, passSpritePattern)
end

--& Draw Sprites
function PPUtoLove2d.DrawSprites(array)
    local numSprites = ((band(ppuIO.CTRL, 0x20) == 0x20) and 64 or 64)
    --fillRamBufferWithColors()
    local spriteHeight = ((band(ppuIO.CTRL, 0x20) == 0x20) and 16 or 8)
    local use8x16Sprites = (spriteHeight == 16)

    for spriteIndex = numSprites - 1, 0, -1 do
        processSprite(array, spriteIndex, spriteHeight, use8x16Sprites)
    end
end

--# 2. Draw a single pass of sprites that are labeled as behind the background
function PPUtoLove2d.DrawBehindSpritesOnly(ptrScreenBuffer)
    local numSprites = 64
    local spriteHeight = ((band(ppuIO.CTRL, 0x20) == 0x20) and 16 or 8)
    local use8x16Sprites = (spriteHeight == 16)

    for spriteIndex = numSprites - 1, 0, -1 do
        local _, _, attributes, _ = getSpriteData(spriteIndex)
            processSprite(ptrScreenBuffer, spriteIndex, spriteHeight, use8x16Sprites)
    end
end

--# 3. Draw a single pass of sprites that are labeled as in front of the background
function PPUtoLove2d.DrawInFrontSpritesOnly(ptrScreenBuffer)
    local numSprites = 64
    local spriteHeight = ((band(ppuIO.CTRL, 0x20) == 0x20) and 16 or 8)
    local use8x16Sprites = (spriteHeight == 16)

    for spriteIndex = numSprites - 1, 0, -1 do
        local _, _, attributes, _ = getSpriteData(spriteIndex)
        local priority = band(attributes, 0x20) == 0 and true or false
        
        if priority == true then
            processSprite(ptrScreenBuffer, spriteIndex, spriteHeight, use8x16Sprites)
        end
    end
end


function Setup1DArray32(colorAddress, ptrScreenBuffer, pixelPosition)
        local color32 = ramBuffer32[colorAddress]
        ptrScreenBuffer[pixelPosition] = color32
end

function Setup1DArray(address,PointerArray, location)
    local color = ramBuffer[address]
    if color ~= nil then
    PointerArray[location],
    PointerArray[location + 1],
    PointerArray[location + 2],
    PointerArray[location + 3] = color[1], color[2], color[3], color[4]
    end
end

--^ HACK CHECK 
function PPUtoLove2d.ScreenToNumbers(CHR1, CHR2)
    local pattern = screenImage
    -- course x y 
    for y=0, 29 do
        for x=0, 31 do
            -- Draw Hex Values of Nametable to screen 
            --if nameTable.tblName[0][1] then love.graphics.print(string.format("%x",nameTable.tblName[0][y*16+x]), x*20+15, y*16+10) end
            -- draw sprites 
            local id = nameTable.tblName[0][y*32+x]
            -- HACK
            if true then
                pattern = CHR1
            else
                pattern = CHR2
            end
            love.graphics.draw(
                pattern,
                love.graphics.newQuad(bit.lshift(bit.band(id, 0x0F), 3), bit.lshift(bit.band(bit.rshift(id, 4), 0x0F), 3), 9, 9, 128, 128),
                x * 16+15, y * 16+10,nil,2
            )
        end
    end
end

--& MAIN DRAW Buffer and Setup
-- DRAW SCREEN
local imageX = 256
local imageY = 240
-- Screen Buffer -- buffer to store the image data This STARTS Alpha 0
local screenBuffer = love.image.newImageData(imageX, imageY, "rgba8")
local screenImage = love.graphics.newImage(screenBuffer)

--# Draw Screen Buffer to Love2d Screen
function PPUtoLove2d.FrameToScreen(buffer)
    screenImage:replacePixels(buffer,0,nil,nil,nil,false)
end

--# Draw Game Window and Scale it to fit the screen
function PPUtoLove2d.GameWindow()
    local screenScale = 2
    local screenX = 0
    if EnableDebug then
        screenScale = 2
        screenX = 15
    else
        screenScale = (love.graphics.getHeight()-25)/240 --* Scale Screen to fit Window
        screenX = love.graphics.getWidth()/2 - (screenImage:getWidth()*screenScale)/2 --* Center Screen in Window 
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(screenImage, screenX, 10, 0, screenScale)
end

return PPUtoLove2d

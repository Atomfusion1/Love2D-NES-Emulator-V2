local cpuMemory = require("NES.CPU.cpuInternal")
local PPUtoLove = require("NES.PPU.PPUtoLove2d")
local ppuIO     = require("NES.PPU.ppuIO")
local OAM     = require("NES.PPU.ppuOAM")
local loopy     = require("NES.PPU.loopy")
local ppuBus    = require("NES.PPU.ppuBus")
local profile   = require("Includes.profile.profile")
local mapper     = require("NES.Cartridge.Mappers")
local cart        = require("NES.Cartridge.Cartridge")

--! Entire PPU is a Hack Job and Needs to be reworked from the ground up but I am lazy and it works so i am not going to touch it
local ppu             = {}
ppu.memory            = {}
ppu.Name              = {}
ppu.Palette           = {}
ppu.Pattern           = {}
ppu.scanLinePixels    = 0
ppu.scanLines         = 30
ppu.vBlankEnd         = false


ppu.scroll = {
    fineX   = 0,
    courseX = 0,
    fineY   = 0,
    courseY = 0
}
function ppu.Initialize(value, chrLocation)
    -- Main PPU (addresses $0200-$FFFF)
    for i = 0x0000, 0xFFFF do
        ppu.memory[i] = bit.band(value, 0xFF)
    end
    print("CHR Location:" .. chrLocation)
end

local band, bor = bit.band, bit.bor
local vBlankFlag = false
local NMIArmed
local scanLinePixels
local scanLines
local CTRL
local STATUS
local Sprite0Scanline
local ppuCycles
local debug = false

--# Main Update PPU Cycle
function ppu.Update(cpuCycles)
    ppuCycles = cpuCycles * 3
    Sprite0Scanline = OAM[0] + 3
    STATUS = ppuIO.STATUS
    CTRL = ppuIO.CTRL
    scanLines = ppu.scanLines
    scanLinePixels = ppu.scanLinePixels
    NMIArmed = ppu.NMIArmed
    while ppuCycles > 0 and not ppu.vBlankEnd do
        --% Increment scanline pixel count
        if debug and scanLinePixels == 0 and scanLines == 0 then
            print("---Start PPU courseX"..loopy.course_x)
        end
        scanLinePixels = scanLinePixels + 1
        loopy.scanLine = scanLines
        --& Check if the first sprite of the scanline is visible
        if scanLines > 8 and scanLines < 241 and scanLines == Sprite0Scanline and not (band(STATUS, 0x40) > 0) then
            ppu.savePPUStates(scanLines + 13)

            STATUS = bor(STATUS, 0x40)
            STATUS = bor(STATUS, 0x20)
            if debug then print("#Sprite0 Hit Scanline "..scanLines) end
        end
        --& Check if we've reached the end of a scanline
        if scanLinePixels >= 341 then
            scanLinePixels = 0
            scanLines = scanLines + 1
            ppuBus.ppuScanLineUpdate(scanLines)
        end
        
        --& Check if we're in vBlank
        if scanLines >= 241  then
            if not (band(STATUS, 0x80) > 0) and vBlankFlag == false then
                vBlankFlag = true
                loopy.inVBlank = true
                --* Set vBlank    
                ppu.savePPUStates(241)
                ppu.postSprite0TileSet = ppuBus.ppuBuffer(0,0x1FFF)
                if loopy.drawScreen then ppu.StartGameWindow() end
                if debug then print("#VBlank Start") end
                STATUS = bor(STATUS,0x80)
            end
            --& Set NMI After VBlank Start by 3 Pixels -- Fixed Solomons Keys Startup
            if scanLines == 241 and scanLinePixels == 3 then
                if NMIArmed and band(CTRL, 0x80) > 0 then
                    --* Set CPU NMI
                    cpuMemory.TriggerNMI = true
                    ppu.NMIArmed = false
                end
            end
            --& Check if vBlank has ended
            if scanLines >= 261 and vBlankFlag == true then
                if debug then print("---VBlank End \n") end
                vBlankFlag = false
                loopy.inVBlank = false
                scanLines = -1
                STATUS = 0x00
                ppu.clearPPUStates()
                ppu.savePPUStates(0)
            end
        end
        --* Decrement cycle count
        ppuCycles = ppuCycles - 1
    end
    ppu.scanLines = scanLines
    ppu.scanLinePixels = scanLinePixels
    ppuIO.STATUS = STATUS
end

--# clear States
function ppu.clearPPUStates()
    loopy.ppuStates = {}
end

--# Loopy Save State 
function ppu.savePPUStates(scanLine)
    local state = {
        scanLine            = scanLine,
        spriteTileSet       = ppuBus.ppuBuffer(0,0x1FFF),
        fineOffset_x        = loopy.fine_x,
        offset_x            = loopy.course_x,
        namespace_x         = loopy.nametable_x,
        fineOffset_y        = loopy.fine_y,
        offset_y            = loopy.course_y,
        namespace_y         = loopy.nametable_y,
        ppuAddress          = loopy.register_vram_addr,
        spriteTable         = ppuIO.SpriteTable,
        backgroundTable     = ppuIO.BackgroundTable,
        mirror              = cart.Mirror,
        isDrawScreen        = loopy.drawScreen,
        isDrawSprites       = loopy.drawSprites
    }
    table.insert(loopy.ppuStates, state)
end

--! MAIN DRAW
-- DRAW SCREEN
local imageX = 256
local imageY = 240
-- Screen Buffer -- buffer to store the image data This STARTS Alpha 0
ppu.screenBuffer = love.image.newImageData(imageX, imageY, "rgba8")
ppu.screenImage = love.graphics.newImage(ppu.screenBuffer)
-- CHR Buffer 0
ppu.patternbuffer0 = love.image.newImageData(128, 128, "rgba8")
ppu.patternScreen0 = love.graphics.newImage(ppu.patternbuffer0)
-- CHR Buffer 1
ppu.patternbuffer1 = love.image.newImageData(128, 128, "rgba8")
ppu.patternScreen1 = love.graphics.newImage(ppu.patternbuffer1)

function ppu.FFIBuffer(ArrayToRender, screenImage, buffer)
    if collectgarbage("count") > 20000 then collectgarbage() end -- This is BAD I do not want this
    local pointer = require("ffi").cast("uint8_t*", buffer:getFFIPointer())
    local pixelCount = (4 * screenImage:getWidth() * screenImage:getHeight()) - 1
    for i = 0, pixelCount, 4 do
        pointer[i] = ArrayToRender[i] or 0
        pointer[i + 1] = ArrayToRender[i + 1] or 0
        pointer[i + 2] = ArrayToRender[i + 2] or 0
        pointer[i + 3] = ArrayToRender[i + 3] or 0
    end
    screenImage:replacePixels(buffer)
end

-- char buffer setup

function ppu.StartGameWindow()
    if Profile then profile.start() end
-- Draw Background with 3F00 Color 
    local ptrScreenBuffer = require("ffi").cast("uint32_t*", ppu.screenBuffer:getFFIPointer())
    PPUtoLove.SetupScreenArray(ptrScreenBuffer)
-- Draw Sprites behind background
    PPUtoLove.DrawBehindSpritesOnly(ptrScreenBuffer)
-- Draw Background 
    if loopy.drawScreen then PPUtoLove.DrawMainScreen(ptrScreenBuffer) end
-- Draw Forground Sprites
    PPUtoLove.DrawInFrontSpritesOnly(ptrScreenBuffer)
-- PPUtoLove.DrawSprites(screenArray)
    PPUtoLove.FrameToScreen(ppu.screenBuffer)
    --ppuOAM.Clear()
    if Profile then
        profile.stop()
        print(profile.report(20))
        profile.reset()
    end
end

local CHR0 = {}
local CHR1 = {}
function ppu.StartCharacterTiles()
    PPUtoLove.DrawCHR(CHR0, 0)
    ppu.FFIBuffer(CHR0, ppu.patternScreen0, ppu.patternbuffer0)
    PPUtoLove.DrawCHR(CHR1, 1)
    ppu.FFIBuffer(CHR1, ppu.patternScreen1, ppu.patternbuffer1)
end

function ppu.StartScreenToNumbers()
    PPUtoLove.ScreenToNumbers(ppu.patternScreen0 , ppu.patternScreen1)
end

function ppu.DrawCharacterTiles()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(ppu.patternScreen0, 10, 500, 0, 2)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(ppu.patternScreen1, 275, 500, 0, 2)
end

return ppu

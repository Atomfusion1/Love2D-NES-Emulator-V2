--! Order Matters .. Cart First for setup  
local cart          = require("NES.Cartridge.Cartridge")
local mapper        = require("NES.Cartridge.Mappers")
local keyboard      = require("Includes.keyboard")
local cpu           = require("NES.CPU.cpumain")
local ppu           = require("NES.PPU.ppu")
local testing       = require("Emulator.UI.Debug.testing")
local apu           = require("NES.Audio.apu")
local pputolove     = require('NES.PPU.PPUtoLove2d')
local selectFile    = require('Emulator.UI.Emulator.selectfile')
local loveSpeed     = require('Includes.loveSpeed')

--* Global Variables
LoveFileDir             = love.filesystem.getSourceBaseDirectory() .. "/" .. love.filesystem.getIdentity() .. "/"
GlobalFileName          = love.filesystem.read("Emulator/nesEmuState.txt")
G_CPUStep               = 2         --# 1 = 1 cycle, 2 = 1 frame
UseSound                = true      --# enable disable sound
EnableDebug             = false     --# enable Debug 
Profile                 = false     --# enable Profiling

--& Run Once on Load
function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    --* Global Cartridge Startup   
    Initialize(GlobalFileName)
end

--& Main Update Loop
function love.update(dt)
    loveSpeed.StartTimer()  --* Start us Timer
    keyboard.Update(dt)     --* Keyboard Update
    apu.TimerCheck(dt)      --* Audio Update 
    --* CPU Execution
    if G_CPUStep == 2 then      --# 2 = 1 frame at a time
        cpu.ExecuteCycles(29780)
    elseif G_CPUStep == 1 then  --# 1 = 1 cycle at a time
        cpu.ExecuteCycles(1)
        G_CPUStep = 0
    end
end

--& Draw Screen
function love.draw()
    DebugDraw()                 --* Debug Tiles and Window 
    pputolove.GameWindow()
    selectFile.DrawPopup()
    loveSpeed.DisplayScreen()   --* Display us Timer 
end

--# Debug Function 
function DebugDraw()
    if EnableDebug then
        testing.DisplayUI()
        ppu.StartCharacterTiles()
        ppu.DrawCharacterTiles()
    end
end

--# Initialize Cartridge
function Initialize (file)
    for i = 1, 5 do
        print("") --* Clear Section of Console
    end
    print(file)
    local totalfile = LoveFileDir .. file
    cart.Initialize(totalfile) --* setup for mappers --
    print("mapper loaded:" .. cart.mapper)
    mapper[cart.mapper].mapper.INI()
    cpu.Initialize()
end

--^ This Uses VSCode BetterComments Colors 
-- You Can see The Settings in Documentation 
--! warning
--@ test 
--# Debug Function 
--% test f8ff97
--^ test BBC2CC
--$ help
--? test
--& test ff7d75
--* test
--TODO Test
-- test 



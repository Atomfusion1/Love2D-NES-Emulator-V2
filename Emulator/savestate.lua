local serpent   = require("Emulator.tabletofile")
local cpuMemory = require("NES.CPU.cpuInternal")
local cart      = require("NES.Cartridge.Cartridge")
local mapper    = require("NES.Cartridge.Mappers")
local cpuRAM    = require("NES.CPU.cpuram")
local ppu       = require("NES.PPU.ppu")
local nameTable = require("NES.PPU.ppunametable")
local ppuOAM    = require("NES.PPU.ppuOAM")
local ppuIO     = require("NES.PPU.ppuIO")
-- Creates a Save State of all the Memory and creates a file 
    -- Define the memory location to store the save state data
    -- Remove the last three letters of the file path and replace them with "batt"

local saveState = {}

local  function createSaveState(table, FILE)
    print("CreateSave "..FILE)
    -- Write the save state data to a file
    local file_path = FILE
    local file = io.open(file_path, "wb")
    if file then
        local serialized_table = serpent.dump(table)
        file:write(serialized_table)
        file:close()
    else
        print("Failed to create save state file at " .. file_path)
    end
end

local table = {
CPU   = {},
PPU   = {},
CART  = {},
OAM   = {},
PPUIO = {}
}
local function updateSaveTable()
        table.CPU.A               =     cpuMemory.A
        table.CPU.X               =     cpuMemory.X
        table.CPU.Y               =     cpuMemory.Y
        table.CPU.stackPointer    =     cpuMemory.stackPointer
        table.CPU.statusRegister  =     cpuMemory.statusRegister
        table.CPU.info_cycle      =     cpuMemory.info.cycle
        table.CPU.info_execute    =     cpuMemory.info.execute
        table.CPU.programCounter  =     cpuMemory.programCounter
        table.CPU.resetInterrupt  =     cpuMemory.resetInterrupt
        table.CPU.NMIInterrupt    =     cpuMemory.NMIInterrupt
        table.CPU.BRKInterrupt    =     cpuMemory.BRKInterrupt
        table.CPU.CHRLocation     =     cpuMemory.CHRLocation
        table.CPU.RAM             =     cpuRAM.cpuRAM

        table.PPU.nCHRBankSelect4Lo     =  mapper[cart.mapper].mapper.nCHRBankSelect4Lo
        table.PPU.nCHRBankSelect4Hi     =  mapper[cart.mapper].mapper.nCHRBankSelect4Hi
        table.PPU.nCHRBankSelect8       =  mapper[cart.mapper].mapper.nCHRBankSelect8
        table.PPU.nPRGBankSelect32      =  mapper[cart.mapper].mapper.nPRGBankSelect32
        table.PPU.nPRGBankSelect16Lo    =  mapper[cart.mapper].mapper.nPRGBankSelect16Lo
        table.PPU.nPRGBankSelect16Hi    =  mapper[cart.mapper].mapper.nPRGBankSelect16Hi

        table.PPU.nControlRegister      = mapper[cart.mapper].mapper.nControlRegister
        table.PPU.nLoadRegister         = mapper[cart.mapper].mapper.nLoadRegister
        table.PPU.nLoadRegisterCount    = mapper[cart.mapper].mapper.nLoadRegisterCount
        table.PPU.prgRAM                = mapper[cart.mapper].mapper.prgRAM
        table.PPU.chrRAM                = mapper[cart.mapper].mapper.chrRAM
        table.PPU.memory                = ppu.memory
        table.PPU.tblName               = nameTable.tblName
        table.PPU.tblPallette           = nameTable.tblPalette

        table.CART.Mirror               = cart.Mirror
        table.OAM.OAM                   = ppuOAM.OAM
        table.PPUIO.NameTableAddress    = ppuIO.NameTableAddress
        table.PPUIO.BackgroundTable     = ppuIO.BackgroundTable
        table.PPUIO.SpriteTable         = ppuIO.SpriteTable
end

function saveState.Save(key)
    updateSaveTable()
    local basename = string.gsub(GlobalFileName, ".nes", "") -- remove the file extension
    basename = string.gsub(basename, "Roms/", "") -- remove the directory path
    local new_file_path = LoveFileDir.."RomSaves/"..basename..key..".save"
    createSaveState(table, new_file_path)
    print("File Saved PC ",new_file_path, table.CPU.stackPointer, string.format("%x",table.CPU.programCounter))
    --print(table.CPU.RAM[0x10])
end

function saveState.LoadFile(file_path)
    print("Loading "..file_path)
    local file = io.open(file_path, "r")
    if file then
        local data = file:read("*all")
        local tableFunction = load(data)
        file:close()
        return true, tableFunction()
    else
        print("Failed to load save state file at " .. file_path)
        return false
    end
end

local function Merge(data)
    --CPU
    cpuMemory.A               = data.CPU.A
    cpuMemory.X               = data.CPU.X
    cpuMemory.Y               = data.CPU.Y
    cpuMemory.stackPointer    = data.CPU.stackPointer
    cpuMemory.statusRegister  = data.CPU.statusRegister
    cpuMemory.info.cycle      = data.CPU.info_cycle
    cpuMemory.info.execute    = data.CPU.info_execute
    cpuMemory.programCounter  = data.CPU.programCounter
    cpuMemory.resetInterrupt  = data.CPU.resetInterrupt
    cpuMemory.NMIInterrupt    = data.CPU.NMIInterrupt
    cpuMemory.BRKInterrupt    = data.CPU.BRKInterrupt
    cpuMemory.CHRLocation     = data.CPU.CHRLocation
    cpuRAM.cpuRAM             = data.CPU.RAM
    --PPU
    mapper[cart.mapper].mapper.nCHRBankSelect4Lo    = data.PPU.nCHRBankSelect4Lo
    mapper[cart.mapper].mapper.nCHRBankSelect4Hi    = data.PPU.nCHRBankSelect4Hi
    mapper[cart.mapper].mapper.nCHRBankSelect8      = data.PPU.nCHRBankSelect8
    mapper[cart.mapper].mapper.nPRGBankSelect32     = data.PPU.nPRGBankSelect32
    mapper[cart.mapper].mapper.nPRGBankSelect16Lo   = data.PPU.nPRGBankSelect16Lo
    mapper[cart.mapper].mapper.nPRGBankSelect16Hi   = data.PPU.nPRGBankSelect16Hi
    mapper[cart.mapper].mapper.prgRAM               = data.PPU.prgRAM
    mapper[cart.mapper].mapper.chrRAM               = data.PPU.chrRAM
    mapper[cart.mapper].mapper.nControlRegister     = data.PPU.nControlRegister
    mapper[cart.mapper].mapper.nLoadRegister        = data.PPU.nLoadRegister
    mapper[cart.mapper].mapper.nLoadRegisterCount   = data.PPU.nLoadRegisterCount
    ppu.memory                                      = data.PPU.memory
    nameTable.tblName                               = data.PPU.tblName
    nameTable.tblPalette                            = data.PPU.tblPallette
    cart.Mirror                                     = data.CART.Mirror
    ppuOAM.OAM                                      = data.OAM.OAM
    if data.PPUIO then
        ppuIO.NameTableAddress                        = data.PPUIO.NameTableAddress
        ppuIO.BackgroundTable                         = data.PPUIO.BackgroundTable
        ppuIO.SpriteTable                             = data.PPUIO.SpriteTable
    end
end


function saveState.Load(key)
    local basename = string.gsub(GlobalFileName, ".nes", "") -- remove the file extension
    basename = string.gsub(basename, "Roms/", "") -- remove the directory path
    local new_file_path = LoveFileDir.."RomSaves/"..basename..(key-6)..".save"
    local condition, data = saveState.LoadFile(new_file_path)
    if condition then
        Initialize(GlobalFileName)
        love.timer.sleep(.1)
        Merge(data)
        love.timer.sleep(.2)
        print("File Loaded PC ", cpuMemory.stackPointer  , string.format("%x",cpuMemory.programCounter))
        love.timer.sleep(.1)
    else
        print("No Save File Found ")
    end
end

return saveState
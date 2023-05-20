local cart = require("NES.Cartridge.Cartridge")

local mapper = {}
mapper.version = 0x01
local CHRoffset

mapper.nCHRBankSelect4Lo = 0x00
mapper.nCHRBankSelect4Hi = 0x00
mapper.nCHRBankSelect8 = 0x00

mapper.nPRGBankSelect16Lo = 0x00
mapper.nPRGBankSelect16Hi = 0x00
mapper.nPRGBankSelect32 = 0x00

mapper.nLoadRegister = 0x00
mapper.nLoadRegisterCount = 0x00
mapper.nControlRegister = 0x00
mapper.A18 = 0x00
mapper.PRGMode = 0x00

mapper.prgRAM = {}
mapper.chrRAM = {}
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift
local debugMAP = false

for i = 0, 0x7FFF do
    mapper.chrRAM[i] = 0x00
end
for i = 0x6000, 0x7FFF do
    mapper.prgRAM[i] = 0x00
end

local function loadSaveState()
    print("LoadSave")
    -- Check if the save state file exists
    local file_path = SAVE_STATE_FILE
    local file = io.open(file_path, "rb")
    if file then
        local data = file:read("*all")
        file:close()
        for i = SAVE_STATE_START_ADDRESS, SAVE_STATE_END_ADDRESS do
            mapper.prgRAM[i] = data:byte(i - SAVE_STATE_START_ADDRESS + 1)
        end
    else
        -- If the save state file doesn't exist, do nothing
        print("No save state file found")
    end
end

local  function createSaveState()
    print("CreateSave")
    -- Write the save state data to a file
    local file_path = SAVE_STATE_FILE
    local file = io.open(file_path, "wb")
    if file then
        local data = ""
        for i = SAVE_STATE_START_ADDRESS, SAVE_STATE_END_ADDRESS do
            data = data .. string.char(mapper.prgRAM[i])
        end
        file:write(data)
        file:close()
    else
        print("Failed to create save state file at " .. file_path)
    end
end

-- Save State prgROM (Battery Backup)
function mapper.load()
    -- check if the file "save_state.bin" exists
    local file_path = SAVE_STATE_FILE
    local file = io.open(file_path, "rb")
    if file then
        -- file exists, load it into memory
        local data = file:read("*all")
        file:close()
        loadSaveState() -- load the save state into memory
    else
        -- file does not exist, create a new save state
        createSaveState()
    end
end

function mapper.CPURead(addr)
    --print(addr)
    -- Cartridge ROM Memory    
    if addr >= 0x6000 and addr <= 0x7FFF then
        return mapper.prgRAM[addr]
    elseif addr >= 0x8000 then
        if band(mapper.nControlRegister, 0x08) ~= 0 then
            -- 16k Mode
            if addr >= 0x8000 and addr <= 0xBFFF then
                --print(string.format ("CPURead %x %x %x ", nPRGBankSelect16Lo, band(addr,0x3FFF), nPRGBankSelect16Lo * 0x4000 + band(addr,0x3FFF) + 0x0010))
                local test = mapper.nPRGBankSelect16Lo * 0x4000 + band(addr,0x3FFF) + 0x0010
                --print(test, cart.ROM[test])
                if mapper.PRGMode == 3 then 
                    return cart.ROM[(mapper.nPRGBankSelect16Lo + mapper.A18) * 0x4000 + band(addr,0x3FFF) + 0x0010]
                else
                    return cart.ROM[(mapper.nPRGBankSelect16Lo) * 0x4000 + band(addr,0x3FFF) + 0x0010]
                end
            end
            if addr >= 0xC000 and addr <= 0xFFFF then
                --print(string.format("%x",addr), band(nControlRegister, 0x08), nPRGBankSelect16Hi, nPRGBankSelect16Hi * 0x4000 + band(addr,0x3FFF) + 0x0010,cart.ROM[nPRGBankSelect16Hi * 0x4000 + band(addr,0x3FFF) + 0x0010])
                if mapper.PRGMode == 2 then
                    return cart.ROM[(mapper.nPRGBankSelect16Hi + mapper.A18 ) * 0x4000 + band(addr,0x3FFF) + 0x0010]
                else
                    return cart.ROM[mapper.nPRGBankSelect16Hi * 0x4000 + band(addr,0x3FFF) + 0x0010]
                end
            end
        else
            --print("32k mode")
            -- 32k Mode
            return cart.ROM[mapper.nPRGBankSelect32 * 0x8000 + band(addr,0x7FFF) + 0x0010]
        end
    end
end

local SaveTimeout = love.timer.getTime()

function mapper.CPUWrite(addr, data)
    if addr >= 0x6000 and addr <= 0x7FFF then
        mapper.prgRAM[addr] = data
        -- Update Cartridge Save every 30 seconds 
        if love.timer.getTime() - SaveTimeout > 30 then
            createSaveState()
            SaveTimeout = love.timer.getTime()
        end
        return
    end
    if addr >= 0x8000 then
        if debugMAP then print("CPU Write 8000+ ", string.format("%x %x", addr, data)) end
        if band(data,0x80) ~= 0 then
            if debugMAP then print("reset") end
            mapper.nLoadRegister = 0x10
            mapper.nLoadRegisterCount = 0x00
            mapper.nControlRegister = bor(mapper.nControlRegister, 0x0C)
        else
            -- load serial data into register
            mapper.nLoadRegister = rshift(mapper.nLoadRegister,1)
            mapper.nLoadRegister = bor(mapper.nLoadRegister, lshift(band(data,0x01), 4))
            mapper.nLoadRegisterCount = mapper.nLoadRegisterCount + 1
            if debugMAP then print(string.format("CPU Write %x %x",addr, data)) end
            if mapper.nLoadRegisterCount == 5 then
                
                -- get Mapper target Register by examining bits 13 and 14
                local nTargetRegister = band(rshift(addr, 13), 0x03)
                if debugMAP then print("Mapper Set Target Register "..nTargetRegister.." Data "..mapper.nControlRegister) end
                if nTargetRegister == 0 then
                    -- set control register
                    mapper.nControlRegister = band(mapper.nLoadRegister, 0x1F)
                    -- Mirror Mode
                    if debugMAP then print("Mirror Mode ", 3-band(mapper.nControlRegister, 0x03)) end
                    cart.Mirror = 3-band(mapper.nControlRegister, 0x03)
                elseif nTargetRegister == 1 then
                    --+----- CHR A16 if CHR = 128k; and PRG ROM A18 if PRG ROM = 512k
                    if cart.header[0x04] == 0x20 and band(mapper.nLoadRegister, 0x10) ~= 0 then mapper.A18 = 0x10 else mapper.A18 = 0x00 end
                    
                    if band(mapper.nControlRegister, 0x10) ~= 0 then
                        mapper.nCHRBankSelect4Lo = band(mapper.nLoadRegister,0x1F)
                    else
                        mapper.nCHRBankSelect8 = band(mapper.nLoadRegister, 0x1E)
                    end
                    if debugMAP then print(string.format("CHRReg1 BankLo:%x BankHi:%x Value:%x, A18:%x",mapper.nCHRBankSelect4Lo,mapper.nCHRBankSelect4Hi, mapper.nLoadRegister, mapper.A18)) end
                elseif nTargetRegister == 2 then
                    --+----- CHR A16 if CHR = 128k; and PRG ROM A18 if PRG ROM = 512k
                    if cart.header[0x04] == 0x20 and band(mapper.nLoadRegister, 0x10) ~= 0 then mapper.A18 = 0x10 else mapper.A18 = 0x00 end
                    
                    if band(mapper.nControlRegister, 0x10) ~= 0 then
                        mapper.nCHRBankSelect4Hi = band(mapper.nLoadRegister,0x1F)
                    end
                    if debugMAP then print(string.format("CHRReg2 BankLo:%x BankHi:%x Value:%x, A18:%x",mapper.nCHRBankSelect4Lo,mapper.nCHRBankSelect4Hi, mapper.nLoadRegister, mapper.A18))  end
                elseif nTargetRegister == 3 then
                    local nPRGMode = band(rshift(mapper.nControlRegister, 2), 0x03)
                    if nPRGMode == 0 or nPRGMode == 1 then
                        mapper.PRGMode = 1
                        mapper.nPRGBankSelect32 = rshift(band(mapper.nLoadRegister, 0x0E), 1)
                    elseif nPRGMode == 2 then
                        mapper.PRGMode = 2
                        mapper.nPRGBankSelect16Lo = 0
                        mapper.nPRGBankSelect16Hi = band(mapper.nLoadRegister, 0x0F)
                    elseif nPRGMode == 3 then
                        mapper.PRGMode = 3
                        mapper.nPRGBankSelect16Lo = band(mapper.nLoadRegister, 0x0F)
                        mapper.nPRGBankSelect16Hi = cart.header[0x04]-1
                    end
                    if debugMAP then print(string.format("PRGReg%d BankLo:%x BankHi:%x A18:%x",nPRGMode ,mapper.nPRGBankSelect16Lo, mapper.nPRGBankSelect16Hi,  mapper.A18)) end
                end
                mapper.nLoadRegister = 0x00
                mapper.nLoadRegisterCount = 0
            end
        end
    end
end

function mapper.PPURead(addr)
    if addr < 0x2000 then
        -- using Cartridge RAM
        if cart.header[0x05] == 0 then
            --print(string.format("PPU Read %x", addr))
            return mapper.chrRAM[addr]
        -- using Cartridge ROM
        else
            if band(mapper.nControlRegister, 0x10) ~= 0 then
                -- 4k CHR Banks
                if addr >= 0x0000 and addr <= 0x0FFF then
                    return cart.ROM[mapper.nCHRBankSelect4Lo * 0x1000 + band(addr, 0x0FFF) + CHRoffset]
                end
                if addr >= 0x1000 and addr <= 0x1FFF then
                    return cart.ROM[mapper.nCHRBankSelect4Hi * 0x1000 + band(addr, 0x0FFF) + CHRoffset]
                end
            else
                -- 8k CHR Bank Mode
                return cart.ROM[mapper.nCHRBankSelect8 * 0x1000 + band(addr, 0x1FFF) + CHRoffset]
            end
        end
    end
end

function mapper.PPUWrite(addr, value)
    -- reset Serial Data
    if addr < 0x2000 then
        if cart.header[0x05] == 0 then
            mapper.chrRAM[addr] = value
            return true
        end
        return true
    else
        return false
    end
end

--[[
    0x8000 - 0xA000 Control Zone 
    0xA000 - 0xC000 CHR low byte 
    0xC000 - 0xE000 CHR Hi byte
    0xE000 - 0xFFFF PRG Rom
]]

function mapper.INI()
    CHRoffset = cart.header[0x04]*0x4000 + 0x0010
    mapper.nControlRegister     = 0x1C
    mapper.nLoadRegister        = 0x00
    mapper.nLoadRegisterCount   = 0x00

    mapper.nCHRBankSelect4Lo   = 0x00
    mapper.nCHRBankSelect4Hi   = 0x00
    mapper.nCHRBankSelect8     = 0x00

    mapper.nPRGBankSelect32    = 0x00
    mapper.nPRGBankSelect16Lo  = 0x00
    mapper.nPRGBankSelect16Hi  = cart.header[0x04]-1
    mapper.A18 = 0x00
    -- Define the memory location to store the save state data
    -- Remove the last three letters of the file path and replace them with "batt"
    local basename = string.gsub(GlobalFileName, ".nes", "") -- remove the file extension
    basename = string.gsub(basename, "Roms/", "") -- remove the directory path
    local new_file_path = LoveFileDir.."RomSaves/"..basename..".batt"
    SAVE_STATE_FILE = new_file_path
    SAVE_STATE_START_ADDRESS = 0x6000
    SAVE_STATE_END_ADDRESS = 0x7FFF
    mapper.load()
end

return mapper
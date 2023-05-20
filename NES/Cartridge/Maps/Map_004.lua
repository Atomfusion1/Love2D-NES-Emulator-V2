local cart = require("NES.Cartridge.Cartridge")

local mapper = {}
mapper.version = 0x03

local CHRoffset
local PRGoffset
local band, bor, lshift, rshift = bit.band, bit.bor, bit.lshift, bit.rshift

local prgBankMode = 0
local chrBankMode = 0
local bankSelect = 0
local irqCounter = 0
local irqLatch = 0
local doIRQ = false
local irqEnable = false
local PRGRAMEnabled = true

local PRGBank6 = 0x00
local PRGBank7 = 0x00

local PRGBankLast = 0x00

--2f
local CHRBank0a = 0x20
local CHRBank0b = 0x21
local CHRBank1a = 0x2a
local CHRBank1b = 0x2b
local CHRBank2 = 0x2c
local CHRBank3 = 0x2d
local CHRBank4 = 0x2e
local CHRBank5 = 0x2f

mapper.prgRAM = {}
for i = 0x6000, 0x7FFF do
    mapper.prgRAM[i] = 0x00
end

function updateBanks()
    -- Update PRG and CHR banks based on bankData and modes
end

function mapper.CPURead(addr)
    --print("CPU read "..addr)
    -- Implement CPURead functionality
    if addr >= 0x6000 and addr < 0x8000 then
        return mapper.prgRAM[addr]
    elseif addr >= 0x8000 and addr < 0xA000 then
        if prgBankMode == 1 then
            return cart.ROM[PRGBankLast * 0x4000 + 0x0000 + band(addr,0x1FFF) + 0x0010]
        else
            return cart.ROM[PRGBank6 * 0x2000 + 0x0000 + band(addr,0x1FFF) + 0x0010]
        end
    elseif addr >= 0xA000 and addr < 0xC000 then
            return cart.ROM[PRGBank7 * 0x2000 + 0x0000 + band(addr,0x1FFF) + 0x0010]
    elseif addr >= 0xC000 and addr < 0xE000 then
        if prgBankMode == 1 then
            return cart.ROM[PRGBank6 * 0x2000 + 0x0000 + band(addr,0x1FFF) + 0x0010]
        else
            return cart.ROM[PRGBankLast * 0x4000 + 0x0000 + band(addr,0x1FFF) + 0x0010]
        end
    elseif addr >= 0xE000 and addr <= 0xFFFF then
        return cart.ROM[PRGBankLast * 0x4000 + 0x2000 + band(addr,0x1FFF) + 0x0010]
    end
end

function mapper.CPUWrite(addr, data)
    -- Implement CPUWrite functionality
    --print(string.format("addr: %x data: %x",addr,data))
    if addr >=0x6000 and addr < 0x8000 then
        mapper.prgRAM[addr] = data
    elseif addr >= 0x8000 and addr < 0xA000 then
        local value = bit.band(addr,0x0001)
        if value == 0 then
            prgBankMode = bit.rshift(bit.band(data,0x40),6)
            chrBankMode = bit.rshift(bit.band(data,0x80),7)
            bankSelect = bit.band(data,0x07)
            --print("prgBankMode "..prgBankMode.." chrBankMode "..chrBankMode.." bankSelect "..bankSelect)
        else
            if bankSelect == 0 then
                CHRBank0a = bit.band(data,0xFFFE)
                CHRBank0b = bit.band(data,0xFFFE) + 1
            elseif bankSelect == 1 then
                CHRBank1a = bit.band(data,0xFFFE)
                CHRBank1b = bit.band(data,0xFFFE) + 1
            elseif bankSelect == 2 then
                CHRBank2 = data
            elseif bankSelect == 3 then
                CHRBank3 = data
            elseif bankSelect == 4 then
                CHRBank4 = data
            elseif bankSelect == 5 then
                CHRBank5 = data
            elseif bankSelect == 6 then
                PRGBank6 = data
                --print("prgbank6 "..PRGBank6 )
            elseif bankSelect == 7 then
                PRGBank7 = data
                --print("prgbank7 "..PRGBank7 )
            end
            --print("BankSelect "..bankSelect.." data "..data)
        end
    elseif addr >= 0xA000 and addr < 0xC000 then
        local value = bit.band(addr,0x0001)
        if value == 0 then
            cart.Mirror = bit.band(data,0x01)==1 and 0 or 1
            --print("Mirror "..cart.Mirror)
        else
            PRGRAMEnabled = bit.band(data, 0x80) == 0x80 and true or false
            --print("PRGRAMEnabled ",PRGRAMEnabled)
        end
    elseif addr >= 0xC000 and addr < 0xE000 then
        local value = bit.band(addr,0x0001)
        if value == 0 then -- Even 
            --print("IRQ Latch "..data)
            irqLatch = data
        else -- Odd
            --print("IRQ Reload "..data)
            irqCounter = irqLatch
        end
    elseif addr >= 0xE000 and addr <= 0xFFFF then
        local value = bit.band(addr,0x0001)
        if value == 0 then -- Even
            --print("IRQ Disabled")
            irqEnable = false
        else -- Odd
            --print("IRQ Enabled")
            irqEnable = true
        end
    end
    --print(string.format("addr: %x data: %x",addr,data))
end

function mapper.PPURead(addr)
    -- Implement PPURead functionality
    if chrBankMode == 0 then
        if addr >= 0x0000 and addr < 0x0400 then
            return cart.ROM[CHRBank0a * 0x0400 + band(addr, 0x03FF) + CHRoffset]
        elseif addr >= 0x0400 and addr < 0x0800 then
            return cart.ROM[CHRBank0b * 0x0400 + band(addr, 0x03FF) + CHRoffset]
        elseif addr >= 0x0800 and addr < 0x0C00 then
            return cart.ROM[CHRBank1a * 0x0400 + band(addr, 0x03FF) + CHRoffset]
        elseif addr >= 0x0C00 and addr < 0x1000 then
            return cart.ROM[CHRBank1b * 0x0400 + band(addr, 0x03FF) + CHRoffset]
        elseif addr >= 0x1000 and addr < 0x1400 then
            return cart.ROM[CHRBank2 * 0x0400 + band(addr, 0x03FF) + CHRoffset]
        elseif addr >= 0x1400 and addr < 0x1800 then
            return cart.ROM[CHRBank3 * 0x0400 + band(addr, 0x03FF) + CHRoffset]
        elseif addr >= 0x1800 and addr < 0x1C00 then
            return cart.ROM[CHRBank4 * 0x0400 + band(addr, 0x03FF) + CHRoffset]
        elseif addr >= 0x1C00 and addr < 0x2000 then
            return cart.ROM[CHRBank5 * 0x0400 + band(addr, 0x03FF) + CHRoffset]
        end
    else
        if addr >= 0x0000 and addr < 0x0400 then
            return cart.ROM[CHRBank2 * 0x0400 + band(addr, 0x03FF) + CHRoffset]
        elseif addr >= 0x0400 and addr < 0x0800 then
            return cart.ROM[CHRBank3 * 0x0400 + band(addr, 0x03FF) + CHRoffset]
        elseif addr >= 0x0800 and addr < 0x0C00 then
            return cart.ROM[CHRBank4 * 0x0400 + band(addr, 0x03FF) + CHRoffset]
        elseif addr >= 0x0C00 and addr < 0x1000 then
            return cart.ROM[CHRBank5 * 0x0400 + band(addr, 0x03FF) + CHRoffset]
        elseif addr >= 0x1000 and addr < 0x1400 then
            return cart.ROM[CHRBank0a * 0x0400 + band(addr, 0x03FF) + CHRoffset]
        elseif addr >= 0x1400 and addr < 0x1800 then
            return cart.ROM[CHRBank0b * 0x0400 + band(addr, 0x03FF) + CHRoffset]
        elseif addr >= 0x1800 and addr < 0x1C00 then
            return cart.ROM[CHRBank1a * 0x0400 + band(addr, 0x03FF) + CHRoffset]
        elseif addr >= 0x1C00 and addr < 0x2000 then
            return cart.ROM[CHRBank1b * 0x0400 + band(addr, 0x03FF) + CHRoffset]
        end
    end
end

function mapper.PPUWrite(addr, value)
    -- Implement PPUWrite functionality
end

function mapper.ScanLineUpdate(scanLines)
    if irqCounter > 0 and scanLines < 241 then
        irqCounter = irqCounter - 1
        --print(scanLines, irqCounter)
    end
    if irqCounter == 0 and irqEnable == true then
        doIRQ = true
        --print("IRQ Ready !!")
        irqCounter = irqLatch
    end
end

function mapper.CheckIRQ()
    if irqEnable == true and doIRQ then
        --print("irq")
        doIRQ = false
        return true
    end
    return false
end

function mapper.INI()
    CHRoffset = cart.header[0x04]*0x4000 + 0x0010
    PRGBankLast = cart.header[0x04]-1
    -- Define the memory location to store the save state data
    -- Remove the last three letters of the file path and replace them with "batt"
    local new_file_path = string.sub(cart.FileName, 1, -5) .. ".batt"
end

return mapper


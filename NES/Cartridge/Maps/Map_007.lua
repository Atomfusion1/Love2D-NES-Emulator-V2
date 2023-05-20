local cart = require("NES.Cartridge.Cartridge")

local mapper = {}
mapper.version = 0x00
local CHRoffset = nil
local functionRead = nil
local PRGROMBank = 0
mapper.chrRAM = {}
for i = 0, 0x7FFF do
    mapper.chrRAM[i] = 0x00
end

function mapper.CPURead(addr)
    --print(PRGROMBank * 0x4000 + bit.band(addr, 0x7FFF) + 0x0010)
    return cart.ROM[PRGROMBank * 0x4000 + bit.band(addr, 0x7FFF) + 0x0010]
end

function mapper.CPUWrite(addr, data)
    PRGROMBank = bit.band(data, 0x07)*2
    --cart.Mirror = bit.band(data, 0x10)==10 and 3 or 0
    --print("CPU Write "..addr.. data, PRGROMBank)
end


    -- Character Memory 
function mapper.PPURead(addr)
        return mapper.chrRAM[addr]
end

function mapper.PPUWrite(addr, data)
    mapper.chrRAM[addr] = data
end

function mapper.INI()
    cart.Mirror = 2 --bit.band(cart.header[0x06], 0x01) == 1 and 1 or 0
    -- 0 - Horizontal Mirror
    -- 1 - Vertical Mirror
    PRGROMBank = cart.header[0x04] - 2
    print("mirror "..cart.Mirror)
    print("mapper initialized Mirror State "..cart.Mirror)
    CHRoffset = cart.header[0x04]*0x4000 + 0x0010 -- offset for header added back on 
end


return mapper
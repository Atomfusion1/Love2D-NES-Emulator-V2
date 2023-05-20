local cart = require("NES.Cartridge.Cartridge")

local mapper = {}
mapper.version = 0x00
local CHRoffset = nil
local functionRead = nil
local ROM = nil
local prgRomBank1 = 0
local chrBank0Latch0 = 0
local chrBank1Latch0 = 0
local chrBank0Latch1 = 0
local chrBank1Latch1 = 0

function mapper.CPURead(addr)
    if addr >= 0xA000 and addr <= 0xFFFF then
        --print(string.format("%x",addr) )
        return cart.ROM[addr - 0xA000 + 0x0010 + ((cart.header[0x04]- 2) * 0x4000 + 0x2000)]
    end
    if addr >= 0x8000 and addr <= 0x9FFF then
        return cart.ROM[addr - 0x8000 + 0x0010 + ((prgRomBank1) * 0x2000)]
    end
    print("Fail To Read")
end

function mapper.CPUWrite(addr, data)
    if addr >= 0xA000 and addr <= 0xAFFF then
        prgRomBank1 = data
    end
    if addr >= 0xB000 and addr <= 0xBFFF then
        chrBank0Latch0 = data
    end
    if addr >= 0xC000 and addr <= 0xCFFF then
        chrBank0Latch1 = data
    end
    if addr >= 0xD000 and addr <= 0xDFFF then
        chrBank1Latch0 = data
    end
    if addr >= 0xE000 and addr <= 0xEFFF then
        chrBank1Latch1 = data
    end
end


    -- Character Memory 
function mapper.PPURead(addr)
    if addr >= 0 and addr <= 0x4000 then
        return ROM[addr + (chrBank0Latch1 * 0x1000) + CHRoffset]
    else
        return ROM[addr + (chrBank1Latch0 * 0x1000) + CHRoffset]
    end

end

function mapper.PPUWrite(addr, data)
    print(addr, data)
end

function mapper.INI()
    cart.Mirror = bit.band(cart.header[0x06], 0x01) == 1 and 1 or 0
    -- 0 - Horizontal Mirror
    -- 1 - Vertical Mirror
    print("mirror "..cart.Mirror)
    print("mapper initialized Mirror State "..cart.Mirror)
    CHRoffset = cart.header[0x04]*0x4000 + 0x0010 -- offset for header added back on 
    ROM = cart.ROM
    print(CHRoffset)
end

return mapper
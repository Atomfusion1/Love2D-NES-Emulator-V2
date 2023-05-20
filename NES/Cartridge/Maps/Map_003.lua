local cart = require("NES.Cartridge.Cartridge")

local band = bit.band
-- UX_ROM 
local mapper = {}
mapper.version = 0x03
mapper.chrBankSelectLo = 0x00   -- Selectable Bank 8000 c0000
mapper.chrBankSelectHi = 0x00
mapper.CHRRAM = {}

for i = 0, 0x7FFF do
    mapper.CHRRAM[i] = 0x00
end

function mapper.CPURead(addr)
    -- Cartridge ROM Memory
    if cart.header[0x04] == 1 and addr >= 0xC000 and addr <= 0xFFFF then
        return cart.ROM[addr - 0xC000 + 0x0010] -- offset for header added back on 
    elseif addr >= 0x8000 and addr <= 0xFFFF then
        return cart.ROM[addr - 0x8000 + 0x0010] -- offset for header added back on 
    else
        return addr
    end
end

function mapper.CPUWrite(addr, value)
    -- Bank select
    if addr >= 0x8000 and addr <= 0xFFFF then
        --print("Bank Select CHR Lo ",addr, value)
        mapper.chrBankSelectLo = band(value, 0x03)
    end
end

function mapper.PPURead(addr)
    -- Character Memory 
    local CHRoffset   = cart.header[0x04]*0x4000
    return cart.ROM[mapper.chrBankSelectLo * 0x2000 + CHRoffset + addr+0x0010] -- offset for header added back on 
end

function mapper.PPUWrite(addr, value)
    --mapper.CHRRAM[addr] = value
    --print("PPU WRITE ERROR IN MAP 03")
    return nil
end

function mapper.INI()

end

return mapper
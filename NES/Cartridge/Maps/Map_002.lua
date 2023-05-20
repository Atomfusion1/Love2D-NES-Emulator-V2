local cart = require("NES.Cartridge.Cartridge")

local band = bit.band
-- UX_ROM 
local mapper = {}
mapper.version = 0x02
mapper.prgBankSelectLo = 0x00   -- Selectable Bank 8000 c0000
mapper.CHRRAM = {}

for i = 0, 0x7FFF do
    mapper.CHRRAM[i] = 0x00
end


function mapper.CPURead(addr)
    mapper.prgBankSelectHi = cart.header[0x04]-1   -- Fixed Bank c000-fffff
    
    -- Cartridge ROM Memory
    if addr >= 0x8000 and addr <= 0xBFFF then
        return cart.ROM[mapper.prgBankSelectLo * 0x4000 + band(addr,0x3FFF) + 0x0010] -- offset for header added back on 
    elseif addr >= 0xC000 and addr <= 0xFFFF then
        return cart.ROM[mapper.prgBankSelectHi * 0x4000 + band(addr,0x3FFF) + 0x0010] -- offset for header added back on 
    else
        return addr
    end
end

function mapper.CPUWrite(addr, value)
    -- Bank select
    if addr >= 0x8000 and addr <= 0xFFFF then
        mapper.prgBankSelectLo = band(value, 0x0F)
    end
end

function mapper.PPURead(addr)
    -- Character Memory 
    return mapper.CHRRAM[addr] -- offset for header added back on 
end

function mapper.PPUWrite(addr, value)
    mapper.CHRRAM[addr] = value
end

function mapper.INI()

end

return mapper
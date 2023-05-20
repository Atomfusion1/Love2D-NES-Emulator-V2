

local ppu = {
    OAM = {}
}

--Sprite OAM Memory PPU Internal Tables
for i = 0x00, 0xFF do
    ppu.OAM[i] = 0x00
end

return ppu.OAM
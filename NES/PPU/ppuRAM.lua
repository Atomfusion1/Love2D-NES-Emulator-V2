-- Nametable and other things
local ppuRAM = {}
ppuRAM.ppuRAM = {}

--Character Tables
for i = 0x2000, 0x3fff do
    ppuRAM.ppuRAM[i] = 0x00
end

return ppuRAM

local cartROM = require("NES.Cartridge.Cartridge")

-- # 2kb internal NES Memory Pagefile, Stack,
local cpuMemory = {}
cpuMemory.cpuRAM = {}
-- 2k ram
for i = 0x0000, 0x0800 do
    cpuMemory.cpuRAM[i] = 0x00
end
-- PPU Registers
for i = 0x2000, 0x2007 do
    cpuMemory.cpuRAM[i] = 0x00
end
-- Other Devices
for i = 0x4000, 0x401F do
    cpuMemory.cpuRAM[i] = 0x00
end
for i=0x5000,0x8000 do
    cpuMemory.cpuRAM[i] = 0x00
end

return cpuMemory

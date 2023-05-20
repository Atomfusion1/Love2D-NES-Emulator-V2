local cart       = require("NES.Cartridge.Cartridge")
local mapper     = require("NES.Cartridge.Mappers")
local memory     = require("NES.CPU.cpuram")
local controller = require("NES.Controller.controller")
local ppuBus     = require("NES.PPU.ppuBus")
local apu        = require("NES.Audio.apu")

local rshift, band, bor = bit.rshift, bit.band, bit.bor

local bus        = {}

--# CPU BUS READ 
function bus.CPURead(addr)
    local CPURAM = memory.cpuRAM
    local cartMapper = mapper[cart.mapper].mapper
    local CPURead = cartMapper.CPURead
--% Read Cartridge Prog Memory ROM
    if addr >= 0x4020 then
        return CPURead(addr)
--% Read Internal CPU RAM
    elseif addr < 0x2000 then
        local cpuRAMIndex    = band(addr, 0x07ff)
        return CPURAM[cpuRAMIndex]
--% Read PPU Registers Directly 
    elseif addr >= 0x2000 and addr <= 0x3FFF then
        addr = band(addr, 0x0007)
        return ppuBus.CPURead(addr)
--% Other CPU Reads (Controller Sound etc)
    elseif addr >= 0x4000 and addr <= 0x401f then
        if addr == 0x4016 or addr == 0x4017 then
            local previousByte = 0x40;
            local controllerData =  controller.ReadState(addr) -- This function reads the raw controller data.
            controllerData = bit.bor(bit.band(controllerData, 0x1F), previousByte) -- Keep the top 3 bits of the previous byte (0x40) and combine with the bottom 5 bits of the current byte.
            --print(string.format("%x", addr), controllerData)
            return controllerData
        end
        if addr == 0x4015 then
            --print("Read Status Length ")
            return 0x0F
        end
        return 0x0
    else
        print(string.format("CPU Error Read not Mapped %x", addr))
        return 0x18
    end
end

--# CPU BUS WRITE
function bus.CPUWrite(addr, data)
    local CPUWrite = ppuBus.CPUWrite
    local CPURAM = memory.cpuRAM
    local cartMapper = mapper[cart.mapper].mapper
    local UseSound = UseSound
--% Write to Internal RAM
    if addr <= 0x1FFF then
        CPURAM[band(addr, 0x07ff)] = data
        return
--% Write to PPU Registers Directly 
    elseif addr >= 0x2000 and addr <= 0x3FFF then
        addr = band(addr, 0x0007)
        CPUWrite(addr, data)
--% Write to Controllers or Other (Sound)
    elseif addr >= 0x4000 and addr <= 0x401f then
        -- Controllers
        if addr == 0x4016 or addr == 0x4017 then
            controller.GetState(addr)
            return
        end
        if addr == 0x4014 then
            ppuBus.CPUWrite(addr, data)
        end
        if addr >= 0x4000 and addr <= 0x400F then
            if UseSound then apu.APUSound(addr, data) end
        end
        if addr == 0x4015 then
            apu.StatusHandle(addr,data)
        end
        if addr == 0x4017 then
            --print("4017 ", data)
        end
    elseif addr >= 0x4020 and addr <= 0xFFFF then
        cartMapper.CPUWrite(addr, data)
    else
        print(string.format("CPU Error Write Memory %x %x", addr, data))
    end
end

--# Check IRQ 
function bus.CheckIRQ()
    if cart.mapper == 4 then
        return mapper[cart.mapper].mapper.CheckIRQ()
    end
end

return bus


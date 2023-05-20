local cpuInternal = require("NES.CPU.cpuInternal")
local mainBus     = require("NES.BUS.bus")

local  band, bor, bnot, rshift, lshift, bxor =  bit.band, bit.bor, bit.bnot, bit.rshift, bit.lshift, bit.bxor
local setFlag, getFlag = cpuInternal.SetFlag, cpuInternal.GetFlag
local cpuRead = mainBus.CPURead
local opcodeFunction = {}

local function IncramentFunction(value)
    value = band(value + 1, 0xFF)
        cpuInternal.statusRegister = ((band(value, 0xFF) == 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x02) or band(cpuInternal.statusRegister, bnot(0x02))
    cpuInternal.statusRegister = ((band(value, 0x80) ~= 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x80) or band(cpuInternal.statusRegister, bnot(0x80))
    return value
end

function opcodeFunction.INYFunction(address)
    local value = cpuInternal.Y
    cpuInternal.Y = IncramentFunction(value)
    return 0,0,0
end

function opcodeFunction.INXFunction(address)
    local value = cpuInternal.X
    cpuInternal.X = IncramentFunction(value)
    return 0,0,0
end

function opcodeFunction.INCFunction(address, addressType)
    local value = cpuRead(address)
    mainBus.CPUWrite(address, IncramentFunction(value))
    return 0,0,0
end

function opcodeFunction.JMPFunction(address)
    cpuInternal.programCounter = address
    return cpuInternal.programCounter, -1, 0
end

function opcodeFunction.JSRFunction(address)
    -- Store Highbyte
    mainBus.CPUWrite(0x100 + cpuInternal.stackPointer , (rshift(band(cpuInternal.programCounter + 2, 0xFF00), 8)))
    cpuInternal.stackPointer    = cpuInternal.stackPointer - 1
    -- Store Lowbyte
    mainBus.CPUWrite(0x100 + cpuInternal.stackPointer , (band(cpuInternal.programCounter + 2, 0xFF)))
    cpuInternal.stackPointer    = cpuInternal.stackPointer - 1
    -- Jump to Target
    cpuInternal.programCounter = mainBus.CPURead(band(cpuInternal.programCounter + 2, 0xFFFF)) * 0x100 + mainBus.CPURead(band(cpuInternal.programCounter + 1, 0xFFFF))
    -- Simplified return statement
    return 0, -1, 0
end

function opcodeFunction.NOPFunction(address)
    return 0, 0, 0
end

function opcodeFunction.LDAFunction(address, addressType)
    local value = cpuRead(address)
    cpuInternal.statusRegister = ((band(value, 0xFF) == 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x02) or band(cpuInternal.statusRegister, bnot(0x02))
    cpuInternal.statusRegister = ((band(value, 0x80) ~= 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x80) or band(cpuInternal.statusRegister, bnot(0x80))
    cpuInternal.A = value
    return cpuInternal.A,0,0
end

function opcodeFunction.LDYFunction(address, addressType)
    local value = cpuRead(address)
    cpuInternal.statusRegister = ((band(value, 0xFF) == 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x02) or band(cpuInternal.statusRegister, bnot(0x02))
    cpuInternal.statusRegister = ((band(value, 0x80) ~= 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x80) or band(cpuInternal.statusRegister, bnot(0x80))
    cpuInternal.Y = value
    return 0,0,0
end

function opcodeFunction.LDXFunction(address, addressType)
    local value = cpuRead(address)
    cpuInternal.statusRegister = ((band(value, 0xFF) == 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x02) or band(cpuInternal.statusRegister, bnot(0x02))
    cpuInternal.statusRegister = ((band(value, 0x80) ~= 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x80) or band(cpuInternal.statusRegister, bnot(0x80))
    cpuInternal.X = value
    return cpuInternal.X, 0, 0
end

function opcodeFunction.LSRFunction(address, addressType)
    local value = (address == nil) and cpuInternal.A or cpuRead(address)
    local result = rshift(value, 1)
    local flag = band(value, 0x01)
    setFlag("carry", flag)
    cpuInternal.statusRegister = ((band(result, 0xFF) == 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x02) or band(cpuInternal.statusRegister, bnot(0x02))
    cpuInternal.statusRegister = ((band(result, 0x80) ~= 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x80) or band(cpuInternal.statusRegister, bnot(0x80))
    if address == nil then
        cpuInternal.A = result
    else
        mainBus.CPUWrite(address, result)
    end
    return 0, 0, 0
end

return opcodeFunction
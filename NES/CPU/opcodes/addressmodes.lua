local cpuInternal   = require("NES.CPU.cpuInternal")
local mainBus         = require("NES.BUS.bus")
--local errorHandler = require("Love2D.errHandle")

local addressMode = {}
local  band, bor, bnot, rshift, lshift, bxor =  bit.band, bit.bor, bit.bnot, bit.rshift, bit.lshift, bit.bxor
addressMode.debugPrint = false
-- Addressing MODES
-- Implied
local CPURead = mainBus.CPURead
local Update16Bit = cpuInternal.Update16Bit
local Update8Bit = cpuInternal.Update8Bit

function addressMode.Accumulator()
    return nil, "Accumulator", 0
end

function addressMode.Implied()
    return nil, "Implied", 0
end

-- Branch Instructions 
function addressMode.Relative()
    return nil, "Relative", 0
end

-- Get Value from next slot in Memory
function addressMode.GetImmediateMode()
    return Update16Bit(cpuInternal.programCounter, 1), "Immediate", 0
end
-- Get Zero Page Address 
function addressMode.GetZeroPageAddressMode()
    local address8BIT = CPURead(Update16Bit(cpuInternal.programCounter, 1))
    return address8BIT, "ZeroPage", 0
end
-- Get ZeroPage_X Address
function addressMode.GetZeroPage_XAddressMode()
    local address   = addressMode.GetZeroPageAddressMode()
    local newAddress = Update8Bit(address ,cpuInternal.X)
    return newAddress, "ZeroPageX", 0
end
-- Get ZeroPage_Y Address
function addressMode.GetZeroPage_YAddressMode()
    local address   = addressMode.GetZeroPageAddressMode()
    local newAddress = Update8Bit(address ,cpuInternal.Y)
    return newAddress, "ZeroPageY", 0
end
-- Get Absolute Address
function addressMode.GetAbsoluteAddressMode()
    local lowbyte = CPURead(band(cpuInternal.programCounter + 1, 0xFFFF))
    local highbyte = CPURead(band(cpuInternal.programCounter + 2, 0xFFFF))
    local address = bor(lshift(highbyte, 8), lowbyte)
    return address, "Absolute", 0
end
-- Get Absolute Indirect Mode
function addressMode.GetAbsoluteIndirectMode()
    local address16 = (mainBus.CPURead(cpuInternal.programCounter+2)*256) + mainBus.CPURead(cpuInternal.programCounter+1)
    -- This Is Fucking Stupid ... Why The Fuck did i spend 1 hour trying to understand this edge case Jump Vector Rolls over does not Pass Page
    return mainBus.CPURead(address16) + (mainBus.CPURead(bit.band(address16,0xFF00)+bit.band(bit.band(address16,0xFF)+1,0xFF)) * 256), "AbsoluteIndirect", 0
end
-- Get Absolute_X Address
function addressMode.GetAbsolute_XAddressMode()
    local cycles = 0
    local absolute  = addressMode.GetAbsoluteAddressMode()
    local newAbsolute = Update16Bit(absolute, cpuInternal.X)
    if (bit.band(absolute, 0xff00)) ~= (bit.band(newAbsolute, 0xff00)) then
        cycles = cycles + 1
    end
    return newAbsolute, "AbsoluteX", cycles
end
-- Get Absolute_Y Address
function addressMode.GetAbsolute_YAddressMode()
    local cycles = 0
    local absolute  = addressMode.GetAbsoluteAddressMode()
    local newAbsolute = Update16Bit(absolute, cpuInternal.Y)
    if (bit.band(absolute, 0xff00)) ~= (bit.band(newAbsolute, 0xff00)) then
        cycles = cycles + 1
    end
    return newAbsolute, "AbsoluteY", cycles
end
-- Get Indexed_Indirect_X
function addressMode.GetIndexed_Indirect_XMode()
    local address8Bit   = Update8Bit(CPURead(Update16Bit(cpuInternal.programCounter, 1)), cpuInternal.X)
    local LowByte16     = CPURead(address8Bit)
    local HighByte16    = CPURead(Update8Bit(address8Bit,1))
    --print(Update8Bit(CPURead(Update16Bit(cpuInternal.programCounter, 1)), cpuInternal.X), HighByte16, LowByte16,(HighByte16 * 0x100) + LowByte16)
    return  ((HighByte16 * 0x100) + LowByte16), "IndexedIndirectX", 0
end
-- Get Indirect_Indexed_Y
function addressMode.GetIndirect_Indexed_YMode()
    local cycles = 0
    local address8Bit   = addressMode.GetZeroPageAddressMode()
    local LowByte16     = CPURead(address8Bit)
    local HighByte16    = CPURead(Update8Bit(address8Bit,1))
    local Address16bit  = ((HighByte16 * 0x100) + LowByte16)
    local Address16AddY = Update16Bit(Address16bit,cpuInternal.Y)
    if (bit.band(Address16bit, 0xff00)) ~= (bit.band(Address16AddY, 0xff00)) then
        cycles = cycles + 1
    end
    return Address16AddY, "IndirectIndexedY", cycles
end

-- Stack Control
function addressMode.WriteToStack(value)
    mainBus.CPUWrite(0x100 + cpuInternal.stackPointer , value)
    cpuInternal.stackPointer    = band(cpuInternal.stackPointer - 1, 0xFF)
end

function addressMode.ReadFromStack()
    cpuInternal.stackPointer    = band(cpuInternal.stackPointer + 1, 0xFF)
    local value                 = CPURead(0x100 + cpuInternal.stackPointer)
    return value
end

return addressMode
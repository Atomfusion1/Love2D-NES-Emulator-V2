local cpuInternal = require("NES.CPU.cpuInternal")
local mainBus     = require("NES.BUS.bus")

local  band, bor, bnot, rshift, lshift, bxor =  bit.band, bit.bor, bit.bnot, bit.rshift, bit.lshift, bit.bxor
local floor = math.floor
local setFlag, getFlag = cpuInternal.SetFlag, cpuInternal.GetFlag
local cpuRead = mainBus.CPURead
local opcodeFunction = {}

-- update flags for ADC
local function CheckADCResults(result, uValue1, uValue2, carry)
    local overflow = (bit.band(bit.bxor(uValue1, uValue2), 0x80) == 0) and (bit.band(bit.bxor(uValue1, result), 0x80) ~= 0)
    setFlag("overflow", overflow and 1 or 0)
    if result > 0xFF then
        setFlag("carry", 1)
    else
        setFlag("carry", 0)
    end
    result = band(result, 0xFF)
    cpuInternal.statusRegister = ((band(result, 0xFF) == 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x02) or band(cpuInternal.statusRegister, bnot(0x02))
    cpuInternal.statusRegister = ((band(result, 0x80) ~= 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x80) or band(cpuInternal.statusRegister, bnot(0x80))

    return result
end

function opcodeFunction.ADCFunction(address, addressType)
    local memoryValue = cpuRead(address)
    local carry = getFlag("carry")
    local result = cpuInternal.A + memoryValue + carry
    cpuInternal.A = CheckADCResults(result, cpuInternal.A ,memoryValue, carry )
    return cpuInternal.A, 0, 0
end

function opcodeFunction.ANDFunction(address, addressType)
    local value = cpuRead(address)
    local result = band(cpuInternal.A, value)
    cpuInternal.statusRegister = ((band(result, 0xFF) == 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x02) or band(cpuInternal.statusRegister, bnot(0x02))
    cpuInternal.statusRegister = ((band(result, 0x80) ~= 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x80) or band(cpuInternal.statusRegister, bnot(0x80))
    cpuInternal.A = result
    return cpuInternal.A, 0, 0
end

local function SetCarryFlag(flagValue)
    if flagValue == 0x01 or flagValue == 0x80 then
        setFlag("carry", 1)
    else
        setFlag("carry", 0)
    end
end

function opcodeFunction.ASLFunction(address, addressType)
    local value = address and cpuRead(address) or cpuInternal.A
    local result = lshift(value, 1)
    result = band(result, 0xFF)
    SetCarryFlag(band(value, 0x80))
    cpuInternal.statusRegister = ((band(result, 0xFF) == 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x02) or band(cpuInternal.statusRegister, bnot(0x02))
    cpuInternal.statusRegister = ((band(result, 0x80) ~= 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x80) or band(cpuInternal.statusRegister, bnot(0x80))
    if address then
        mainBus.CPUWrite(address, result)
    else
        cpuInternal.A = result
    end
    return 0, 0, 0
end

-- Function for branching instructions (BCS, BCC, etc.)
-- If the condition is true, reads the offset value from the next byte
-- Adjusts the program counter by the offset, which can be negative
-- Returns the new program counter and the number of cycles taken
function BranchFunction(value)
    local cycles = 0
    if value then
        cycles = 1
        local offsetValue = mainBus.CPURead(cpuInternal.Update16Bit(cpuInternal.programCounter, 1))
        -- If the offset value is negative, subtract 256 to get a signed value
        if offsetValue >= 0x80 then
            offsetValue = offsetValue - 0x100
        end
        -- Adjust the program counter by the offset value plus 2 (for the opcode and offset bytes)
        local oldPC = cpuInternal.programCounter
        cpuInternal.programCounter = (oldPC + 2 + offsetValue)
        if (bit.band(cpuInternal.programCounter , 0xff00)) ~= (bit.band(oldPC, 0xff00)) then
            cycles = cycles + 0
        end
        return cpuInternal.programCounter, -2, cycles
    end
    return 0, 0, 0
end

function opcodeFunction.BCSFunction(address)
    local value = (getFlag("carry") == 1)
    return BranchFunction(value)
end

function opcodeFunction.BCCFunction(address)
    local value = (getFlag("carry") == 0)
    return BranchFunction(value)
end

function opcodeFunction.BPLFunction(address)
    local value = (getFlag("negative") == 0)
    return BranchFunction(value)
end

function opcodeFunction.BMIFunction(address)
    local value = (getFlag("negative") == 1)
    return BranchFunction(value)
end

function opcodeFunction.BEQFunction(address)
    local value = (getFlag("zero") == 1)
    return BranchFunction(value)
end

function opcodeFunction.BNEFunction(address)
    local value = (getFlag("zero") == 0)
    return BranchFunction(value)
end

function opcodeFunction.BVCFunction(address)
    local value = (getFlag("overflow") == 0)
    return BranchFunction(value)
end

function opcodeFunction.BVSFunction(address)
    local value = (getFlag("overflow") == 1)
    return BranchFunction(value)
end

function opcodeFunction.BITFunction(address, addressType)
    local value = cpuRead(address)
    local result = band(cpuInternal.A, value)
    setFlag("zero", (band(result, 0xFF) == 0) and 1 or 0)
    setFlag("negative", (band(value, 0x80) ~= 0) and 1 or 0)
    local overflow = (band(value, 0x40) == 0x40) and 1 or 0
    setFlag("overflow", overflow)
    return 0, 0, 0
end

function opcodeFunction.CLCFunction(address)
    setFlag("carry", 0)
    return 0, 0, 0
end

function opcodeFunction.CLDFunction(address)
    setFlag("decimal", 0)
    return 0, 0, 0
end

function opcodeFunction.CLIFunction(address)
    setFlag("interrupt", 0)
    return 0, 0, 0
end

function opcodeFunction.CLVFunction(address)
    setFlag("overflow", 0)
    return 0, 0, 0
end

function CompareFunction(operand1, operand2)
    local result = operand1 - operand2
    result = band(result, 0xFF)
    -- Set the Carry Flag
    setFlag("carry", operand1 >= operand2 and 1 or 0)
    -- Set the Zero Flag
    setFlag("zero", operand1 == operand2 and 1 or 0)
    -- Set the Negative Flag
    setFlag("negative", (band(result, 0x80) ~= 0) and 1 or 0)
    return 0, 0, 0
end

function opcodeFunction.CMPFunction(address, addressType)
    local operand2 = cpuRead(address)
    local operand1 = cpuInternal.A
    return CompareFunction(operand1, operand2)
end

function opcodeFunction.CPYFunction(address, addressType)
    local operand2 = cpuRead(address)
    local operand1 = cpuInternal.Y
    return CompareFunction(operand1, operand2)
end

function opcodeFunction.CPXFunction(address, addressType)
    local operand2 = cpuRead(address)
    local operand1 = cpuInternal.X
    return CompareFunction(operand1, operand2)
end

local function DecrementFunction(value)
    local value = band(value - 1, 0xFF)
        cpuInternal.statusRegister = ((band(value, 0xFF) == 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x02) or band(cpuInternal.statusRegister, bnot(0x02))
    cpuInternal.statusRegister = ((band(value, 0x80) ~= 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x80) or band(cpuInternal.statusRegister, bnot(0x80))
    return value
end

function opcodeFunction.DEYFunction(address)
    local value = cpuInternal.Y
    cpuInternal.Y = DecrementFunction(value)
    return 0,0,0
end

function opcodeFunction.DEXFunction(address)
    local value = cpuInternal.X
    cpuInternal.X = DecrementFunction(value)
    return 0,0,0
end

function opcodeFunction.DECFunction(address, addressType)
    local value = cpuRead(address)
    mainBus.CPUWrite(address, DecrementFunction(value))
    return 0,0,0
end

function opcodeFunction.EORFunction(address, addressType)
    local value = cpuRead(address)
    local result = bxor(cpuInternal.A, value)
    cpuInternal.statusRegister = ((band(result, 0xFF) == 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x02) or band(cpuInternal.statusRegister, bnot(0x02))
    cpuInternal.statusRegister = ((band(result, 0x80) ~= 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x80) or band(cpuInternal.statusRegister, bnot(0x80))
    cpuInternal.A = result
    return 0,0,0
end

return opcodeFunction
local cpuInternal = require("NES.CPU.cpuInternal")
local mainBus     = require("NES.BUS.bus")
local addressMode = require("NES.CPU.opcodes.addressmodes")

local  band, bor, bnot, rshift, lshift, bxor =  bit.band, bit.bor, bit.bnot, bit.rshift, bit.lshift, bit.bxor
local floor = math.floor
local setFlag, getFlag = cpuInternal.SetFlag, cpuInternal.GetFlag
local cpuRead = mainBus.CPURead
local opcodeFunction = {}

-- Check Zero Flag
local function CheckZeroFlag(value)
    local result = (band(value, 0xFF) == 0) and 1 or 0
    setFlag("zero", result)
end

local function CheckNegativeFlag(value)
    local result = (band(value, 0x80) ~= 0) and 1 or 0
    setFlag("negative", result)
end

-- Check Zero and Negative Flag
local function CheckZeroAndNegativeFlag(value)
    local resultZero = (band(value, 0xFF) == 0) and 1 or 0
    setFlag("zero", resultZero)
    local resultNegative = (band(value, 0x80) ~= 0) and 1 or 0
    setFlag("negative", resultNegative)
end

function opcodeFunction.NOPFunction(address)
    return 0, 0, 0
end

function opcodeFunction.LAXFunction(address)
    local value = cpuRead(address)
    cpuInternal.A = value
    cpuInternal.X = value
    CheckZeroAndNegativeFlag(value)    
    return cpuInternal.X, 0, 0
end

function opcodeFunction.SAXFunction(address)
    local value = band(cpuInternal.A, cpuInternal.X)
    mainBus.CPUWrite(address, value)
    return value,0,0
end

function CompareFunction(operand1, operand2)
    local result = operand1 - operand2
    result = band(result, 0xFF)
    -- Set the Carry Flag
    setFlag("carry", operand1 >= operand2 and 1 or 0)
    -- Set the Zero Flag
    setFlag("zero", operand1 == operand2 and 1 or 0)
    -- Set the Negative Flag
    CheckNegativeFlag(result)
    return 0, 0, 0
end

local function DecrementFunction(value)
    value = band(value - 1, 0xFF)
    CheckZeroAndNegativeFlag(value)
    return value
end
-- i dont care this is slow no one should be using it much 
function opcodeFunction.DCPFunction(address)
    local value = cpuRead(address)
    mainBus.CPUWrite(address, DecrementFunction(value))

    local operand2 = cpuRead(address)
    local operand1 = cpuInternal.A
    return CompareFunction(operand1, operand2)
end

local function IncramentFunction(value)
    value = band(value + 1, 0xFF)
    CheckZeroAndNegativeFlag(value)
    return value
end


local function CheckOverflowFlagSBC( result, operand1, operand2)
    -- Check for Overflow
    local overflow = (band(bxor(operand1, operand2), 0x80) ~= 0) and (band(bxor(operand1, result), 0x80) ~= 0)
        setFlag("overflow",(overflow == true) and 1 or 0)
end

-- update flags for SBC
local function CheckSBCResults(result, operand1, operand2)
    if result < 0x00 then
        setFlag("carry",0)
        result = band(result,0xFF)
    else
        setFlag("carry",1)
    end
    result = band(result,0xFF)
    CheckZeroAndNegativeFlag(result)
    CheckOverflowFlagSBC(result, operand1, operand2 )
    return result
end

-- inc 1 then subtract 
function opcodeFunction.ISCFunction(address)
    local value = cpuRead(address)
    mainBus.CPUWrite(address, IncramentFunction(value))

    value = cpuRead(address)
    local carry = getFlag("carry")
    local result = cpuInternal.A - value - (1 - carry)
    cpuInternal.A = CheckSBCResults(result, cpuInternal.A ,value )
    return cpuInternal.A, 0, 0
end

local function SetCarryFlag(flagValue)
    if flagValue == 0x01 or flagValue == 0x80 then
        setFlag("carry", 1)
    else
        setFlag("carry", 0)
    end
end

function opcodeFunction.SLOFunction(address)
    local value = address and cpuRead(address) or cpuInternal.A
    local result = lshift(value, 1)
    result = band(result, 0xFF)
    SetCarryFlag(band(value, 0x80))
    CheckZeroAndNegativeFlag(result)
    if address then
        mainBus.CPUWrite(address, result)
    else
        cpuInternal.A = result
    end

    value = cpuRead(address)
    local results = bor(cpuInternal.A, value)
    CheckZeroAndNegativeFlag(results)
    cpuInternal.A = results
    return 0,0,0
end

function opcodeFunction.RLAFunction(address)
    local value = cpuRead(address)
    local result = bor(lshift(value, 1), getFlag("carry"))
    result = band(result, 0xFF)
    SetCarryFlag(band(value, 0x80))
    CheckZeroAndNegativeFlag(result)
    mainBus.CPUWrite(address, result)

    value = cpuRead(address)
    local results = band(cpuInternal.A, value)
    CheckZeroAndNegativeFlag(results)
    cpuInternal.A = results
    return cpuInternal.A, 0, 0
end

function opcodeFunction.SREFunction(address)
    local value = cpuRead(address)
    local result = rshift(value, 1)
    local flag = band(value, 0x01)
    setFlag("carry", flag)
    CheckZeroAndNegativeFlag(result)
    mainBus.CPUWrite(address, result)
        
    value = cpuRead(address)
    local results = bxor(cpuInternal.A, value)
    CheckZeroAndNegativeFlag(results)
    cpuInternal.A = results
    return 0,0,0
end

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

-- This is not right but close 
function opcodeFunction.RRAFunction(address)
    -- ror
    local value = cpuRead(address)
    --print(getFlag("carry"))
    local result = bor(rshift(value, 1), lshift(getFlag("carry"), 7))
    SetCarryFlag(band(value, 0x01))
    CheckZeroAndNegativeFlag(result)
    mainBus.CPUWrite(address, result)
    
    -- adc
    value = cpuRead(address)
    local carry = getFlag("carry")
    result = cpuInternal.A + value + carry
    cpuInternal.A = CheckADCResults(result, cpuInternal.A ,value, carry )
    return cpuInternal.A, 0, 0
end


return opcodeFunction
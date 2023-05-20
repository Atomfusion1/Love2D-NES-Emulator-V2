local cpuInternal = require("NES.CPU.cpuInternal")
local mainBus     = require("NES.BUS.bus")
local addressMode = require("NES.CPU.opcodes.addressmodes")

local  band, bor, bnot, rshift, lshift, bxor =  bit.band, bit.bor, bit.bnot, bit.rshift, bit.lshift, bit.bxor
local floor = math.floor
local setFlag, getFlag = cpuInternal.SetFlag, cpuInternal.GetFlag
local cpuRead = mainBus.CPURead
local opcodeFunction = {}

function opcodeFunction.ORAFunction(address, addressType)
    local value = cpuRead(address)
    local result = bor(cpuInternal.A, value)
    cpuInternal.statusRegister = ((band(result, 0xFF) == 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x02) or band(cpuInternal.statusRegister, bnot(0x02))
    cpuInternal.statusRegister = ((band(result, 0x80) ~= 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x80) or band(cpuInternal.statusRegister, bnot(0x80))
    cpuInternal.A = result
    return 0,0,0
end

function opcodeFunction.PHPFunction(address)
    local value = bor(cpuInternal.statusRegister,0x30)
    addressMode.WriteToStack(value)
    return 0, 0, 0
end

function opcodeFunction.PLAFunction(address)
    local result = addressMode.ReadFromStack()
    cpuInternal.statusRegister = ((band(result, 0xFF) == 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x02) or band(cpuInternal.statusRegister, bnot(0x02))
    cpuInternal.statusRegister = ((band(result, 0x80) ~= 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x80) or band(cpuInternal.statusRegister, bnot(0x80))
    cpuInternal.A = result
    return 0, 0, 0
end

function opcodeFunction.PHAFunction(address)
    addressMode.WriteToStack(cpuInternal.A)
    return 0, 0, 0
end

function opcodeFunction.PLPFunction(address)
    local value = addressMode.ReadFromStack()
    value = bor(value, 0x20)
    value = band(value, 0xEF)
    cpuInternal.statusRegister = value
    return 0, 0, 0
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
    cpuInternal.statusRegister = ((band(result, 0xFF) == 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x02) or band(cpuInternal.statusRegister, bnot(0x02))
    cpuInternal.statusRegister = ((band(result, 0x80) ~= 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x80) or band(cpuInternal.statusRegister, bnot(0x80))
    CheckOverflowFlagSBC(result, operand1, operand2 )
    return result
end

function opcodeFunction.SBCFunction(address, addressType)
    local value = cpuRead(address)
    local carry = getFlag("carry")
    local result = cpuInternal.A - value - (1 - carry)
    cpuInternal.A = CheckSBCResults(result, cpuInternal.A ,value )
    return cpuInternal.A, 0, 0
end

function opcodeFunction.SECFunction(address)
    setFlag("carry", 1)
    return 1, 0, 0
end

function opcodeFunction.SEIFunction(address)
    setFlag("interrupt", 1)
    return 1, 0, 0
end

function opcodeFunction.SEDFunction(address)
    setFlag("decimal", 1)
    return 1, 0, 0
end

function opcodeFunction.STAFunction(address, addressType)
    mainBus.CPUWrite(address, cpuInternal.A)
    return cpuInternal.A,0,0
end

function opcodeFunction.STXFunction(address, addressType)
    mainBus.CPUWrite(address, cpuInternal.X)
    return address, 0, 0
end

function opcodeFunction.STYFunction(address, addressType)
    mainBus.CPUWrite(address, cpuInternal.Y)
    return address, 0, 0
end

function opcodeFunction.RTSFunction(address)
    -- Get Low Byte
    local lowbyte = addressMode.ReadFromStack()
    -- Get High Byte
    local highbyte = addressMode.ReadFromStack() * 0x100
    -- Jump to Target -- add 1 to target address
    cpuInternal.programCounter = highbyte + lowbyte + 1
    return 0, 0, 0
end

local function setCarryFlag(flagValue)
    if flagValue == 0x01 or flagValue == 0x80 then
        setFlag("carry", 1)
    else
        setFlag("carry", 0)
    end
end

function opcodeFunction.RORFunction(address, addressType)
    local value = address and cpuRead(address) or cpuInternal.A
    local result = bor(rshift(value, 1), lshift(getFlag("carry"), 7))
    setCarryFlag(band(value, 0x01))
    cpuInternal.statusRegister = ((band(result, 0xFF) == 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x02) or band(cpuInternal.statusRegister, bnot(0x02))
    cpuInternal.statusRegister = ((band(result, 0x80) ~= 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x80) or band(cpuInternal.statusRegister, bnot(0x80))
    if address then
        mainBus.CPUWrite(address, result)
    else
        cpuInternal.A = result
    end
    return 0, 0, 0
end

function opcodeFunction.ROLFunction(address, addressType)
    local value = address and cpuRead(address) or cpuInternal.A
    local result = bor(lshift(value, 1), getFlag("carry"))
    result = band(result, 0xFF)
    setCarryFlag(band(value, 0x80))
    cpuInternal.statusRegister = ((band(result, 0xFF) == 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x02) or band(cpuInternal.statusRegister, bnot(0x02))
    cpuInternal.statusRegister = ((band(result, 0x80) ~= 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x80) or band(cpuInternal.statusRegister, bnot(0x80))
    if address then
        mainBus.CPUWrite(address, result)
    else
        cpuInternal.A = result
    end
    return 0, 0, 0
end

function opcodeFunction.RTIFunction(value)
    -- Get Past Flag Status
    local flagByte = addressMode.ReadFromStack()
    -- Flag must have bit 5 high
    flagByte = bor(flagByte, 0x20)
    cpuInternal.statusRegister = flagByte
    -- Get Low Byte
    local lowbyte = addressMode.ReadFromStack()
    -- Get High Byte
    local highbyte = addressMode.ReadFromStack() * 256
    local targetAddress = highbyte + lowbyte
    -- Jump to Target
    cpuInternal.programCounter = targetAddress
    return 0,-1,0
end

function opcodeFunction.TAXFunction(address)
    local result = cpuInternal.A
    cpuInternal.statusRegister = ((band(result, 0xFF) == 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x02) or band(cpuInternal.statusRegister, bnot(0x02))
    cpuInternal.statusRegister = ((band(result, 0x80) ~= 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x80) or band(cpuInternal.statusRegister, bnot(0x80))
    cpuInternal.X = result
    return 0,0,0
end

function opcodeFunction.TAYFunction(address)
    local value = cpuInternal.A
    cpuInternal.statusRegister = ((band(value, 0xFF) == 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x02) or band(cpuInternal.statusRegister, bnot(0x02))
    cpuInternal.statusRegister = ((band(value, 0x80) ~= 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x80) or band(cpuInternal.statusRegister, bnot(0x80))
    cpuInternal.Y = value
    return 0,0,0
end

function opcodeFunction.TXAFunction(address)
    local value = cpuInternal.X
    cpuInternal.statusRegister = ((band(value, 0xFF) == 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x02) or band(cpuInternal.statusRegister, bnot(0x02))
    cpuInternal.statusRegister = ((band(value, 0x80) ~= 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x80) or band(cpuInternal.statusRegister, bnot(0x80))
    cpuInternal.A = value
    return 0,0,0
end

function opcodeFunction.TYAFunction(address)
    local value = cpuInternal.Y
    cpuInternal.statusRegister = ((band(value, 0xFF) == 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x02) or band(cpuInternal.statusRegister, bnot(0x02))
    cpuInternal.statusRegister = ((band(value, 0x80) ~= 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x80) or band(cpuInternal.statusRegister, bnot(0x80))
    cpuInternal.A = value
    return 0,0,0
end

function opcodeFunction.TSXFunction(address)
    local value = cpuInternal.stackPointer
    cpuInternal.statusRegister = ((band(value, 0xFF) == 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x02) or band(cpuInternal.statusRegister, bnot(0x02))
    cpuInternal.statusRegister = ((band(value, 0x80) ~= 0) and 1 or 0 == 1) and bor(cpuInternal.statusRegister, 0x80) or band(cpuInternal.statusRegister, bnot(0x80))
    cpuInternal.X = value
    return 0,0,0
end

function opcodeFunction.TXSFunction(address)
    local value = cpuInternal.X
    cpuInternal.stackPointer = value
    return 0,0,0
end

return opcodeFunction
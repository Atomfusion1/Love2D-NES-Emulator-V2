local cpuInternal = require("NES.CPU.cpuInternal")
local mainBus     = require("NES.BUS.bus")

local  band, bor, bnot, rshift, lshift, bxor =  bit.band, bit.bor, bit.bnot, bit.rshift, bit.lshift, bit.bxor
local floor = math.floor
local setFlag, getFlag = cpuInternal.SetFlag, cpuInternal.GetFlag
local cpuRead = mainBus.CPURead
local opcodefunction = {}

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

return opcodefunction
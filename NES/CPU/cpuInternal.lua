
local  band, bor, bnot, rshift, lshift =  bit.band, bit.bor, bit.bnot, bit.rshift, bit.lshift

local cpuInternal          = {}
-- Basic 6502 Registers and Storage
cpuInternal                = {}
cpuInternal.A              = 0x00
cpuInternal.X              = 0x00
cpuInternal.Y              = 0x00
cpuInternal.stackPointer   = 0xFF
cpuInternal.statusRegister = 0x24
cpuInternal.programCounter = 0xFFFF
cpuInternal.BRKInterrupt   = 0xFFFF
cpuInternal.NMIAddress     = 0xFFFF
cpuInternal.flag           = {
    ["negative"]  = 0x80, -- 7 = negative flag N
    ["overflow"]  = 0x40, -- 6 = overflow flag V
    ["none"]      = 0x20, -- 5 = always high Not Used
    ["breakflow"] = 0x10, -- 4 = breakflow flag B
    ["decimal"]   = 0x08, -- 5 = decimal flag D
    ["interrupt"] = 0x04, -- 3 = interrupt flag I
    ["zero"]      = 0x02, -- 2 = zero flag Z
    ["carry"]     = 0x01, -- 1 = carry flag C
}
--additional information I Wanted
cpuInternal.StartNMI       = false
cpuInternal.StartBreak     = false
cpuInternal.StartReset     = false
-- Debug Internal CPU
cpuInternal.info           = {}
cpuInternal.info.cycle     = 0
cpuInternal.info.execute   = 0

-- UPDATE BYTES
-- update 16 bit value check for rollover
function cpuInternal.Update16Bit(value, change)
    value = band((value + change), 0xFFFF)
    return value
end

-- Update 8 bit values check for rollover
function cpuInternal.Update8Bit(value, change)
    value = band((value + change), 0xFF)
    return value
end

-- HANDLE FLAGS
-- Read Flag
function cpuInternal.GetFlag(flag)
    local value = cpuInternal.flag[flag]
    return (band(cpuInternal.statusRegister, value) == value) and 1 or 0
end

-- Write to Flag
function cpuInternal.SetFlag(flag, value)
    local flagValue = cpuInternal.flag[flag]
    if value == 1 then
        cpuInternal.statusRegister = bor(cpuInternal.statusRegister, flagValue)
    else
        cpuInternal.statusRegister = band(cpuInternal.statusRegister, bnot(flagValue))
    end
end

return cpuInternal
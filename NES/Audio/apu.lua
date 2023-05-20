local pulseSound = require("NES.Audio.apu_pulse")
local triangleSound = require("NES.Audio.apu_triangle")
local noiseSound = require("NES.Audio.apu_noise")

VolumeMulti = 5 --& Global Value for Volume Multiplier
local apu = {}

--# Handle APU Updates Per Frame
function apu.TimerCheck(dt)
    pulseSound.UpdatePulse(1, dt)
    pulseSound.UpdatePulse(2, dt)
    triangleSound.UpdateTriangle(dt)
    noiseSound.UpdateNoise(dt)
end

--# Sound Off
function SoundOff()
    pulseSound.StopPulseNote(1)
    pulseSound.StopPulseNote(2)
    triangleSound.StopTriangle()
    noiseSound.StopNoise()
end

--# Handle APU Status Handles
function apu.StatusHandle(addr, data)
    if addr == 0x4015 and bit.band(data,0x01) == 0 then
        pulseSound.StopPulseNote(1)
    end
    if addr == 0x4015 and bit.band(data,0x02) == 0 then
        pulseSound.StopPulseNote(2)
    end
    if addr == 0x4015 and bit.band(data,0x03) == 0 then
        triangleSound.StopTriangle()
    end
    if addr == 0x4015 and bit.band(data,0x04) == 0 then
        noiseSound.StopNoise()
    end
end

--# Handle APU Addresses
function apu.APUSound(addr, data)
    --@ Pulse 1
    if addr >= 0x4000 and addr <= 0x4003 then
        pulseSound.HandlePulse(1, addr, data)
    end
    --@ Pulse 2
    if addr >= 0x4004 and addr <= 0x4007 then
        pulseSound.HandlePulse(2, addr, data)
    end
    --@ Triangle
    if addr >= 0x4008 and addr <= 0x400B then
        triangleSound.HandleTriangle(addr, data)
    end
    --@ Noise
    if addr >= 0x400C and addr <= 0x400F then
        noiseSound.HandleNoise(addr, data)
    end
end

--# Initialize Sound Sources
function apu.Initialize()
    SoundOff()
    return apu
end

return apu
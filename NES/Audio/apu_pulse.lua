local lengthTable = require("NES.Audio.lengthcounter").LoadCounterTable()

local apu_Pulse = {}

--* Debug number to binary
local function numToBinary(num, bitLength)
    bitLength = bitLength or 8
    local binary = ""
    while num > 0 do
        local remainder = num % 2
        binary = tostring(remainder) .. binary
        num = math.floor(num / 2)
    end
    while #binary < bitLength do
        binary = "0" .. binary
    end
    return binary
end

--* Pulse Sound Sources
local pulseSource = require("NES.Audio.pulseGenerator")

--% Pulse Variable Setup
apu_Pulse.MainVolume = .001
apu_Pulse.apuDebug = {false, false}
apu_Pulse.playingNote = {127, 127}
apu_Pulse.playingDutyCycle = {0, 0}
apu_Pulse.isNotePlaying = {false, false}
apu_Pulse.timerValue = {0, 0}
apu_Pulse.dutyCycle = {0, 0}
apu_Pulse.LCHalt = {0, 0}
apu_Pulse.constVolume = {0, 0}
apu_Pulse.volume = {0, 0}
apu_Pulse.elapsedTime = {0, 0}
apu_Pulse.elapsedTimeLength = {0, 0}
apu_Pulse.sweepEnabled = {false, false}
apu_Pulse.sweepPeriod = {0, 0}
apu_Pulse.sweepNegate = {false, false}
apu_Pulse.sweepShift = {0, 0}
apu_Pulse.sweepCounter = {0, 0}
apu_Pulse.sweepElapsedTime = {0,0}
apu_Pulse.LCTimer = {0, 0}
apu_Pulse.LCTimerLength = {0, 0}
local maxNoteHeight = 255 -- Set the maximum allowed note height; adjust this value as needed

--# Stop Pulse Note
function apu_Pulse.StopPulseNote(channel)
    pulseSource[channel][apu_Pulse.playingNote[channel]][apu_Pulse.playingDutyCycle[channel]]:setVolume(0)
    pulseSource[channel][apu_Pulse.playingNote[channel]][apu_Pulse.playingDutyCycle[channel]]:stop()
    apu_Pulse.isNotePlaying[channel] = false
end

--# Adjust Pulse Note Volume
function apu_Pulse.AdjustVolume(channel,volume)
    require('jit').off()
    local setVolume = volume * apu_Pulse.MainVolume * VolumeMulti
    -- audio hack to stop love2d from crashing from sweep and Envelope Failed 
    if setVolume > 1 then setVolume = 1 end
    if setVolume < 0.001 then setVolume = 0 end
    pulseSource[channel][apu_Pulse.playingNote[channel]][apu_Pulse.playingDutyCycle[channel]]:setVolume(setVolume)
    require('jit').on()
end 

--# Play Pulse Note
function apu_Pulse.PlayPulseNote(channel, note, volume, dutyCycle)
    require('jit').off()
    if apu_Pulse.playingNote[channel] == note and apu_Pulse.isNotePlaying[channel] then  return end
    --& Set volume to 0 and stop any playing notes
        apu_Pulse.StopPulseNote(channel)
    --& Set volume to level and play
    if note < maxNoteHeight then
        pulseSource[channel][note][dutyCycle]:setVolume(volume * apu_Pulse.MainVolume * VolumeMulti)
        pulseSource[channel][note][dutyCycle]:play()

        apu_Pulse.isNotePlaying[channel] = true
        apu_Pulse.playingNote[channel] = note
        apu_Pulse.playingDutyCycle[channel] = dutyCycle
        apu_Pulse.elapsedTime[channel] = 0
        apu_Pulse.LCTimer[channel] = 0
        apu_Pulse.sweepElapsedTime[channel]=0
    end
    require('jit').on()
end

--# Pulse Channel Length Timer Update
function LengthUpdate(channel, dt)
    require('jit').off()
    if apu_Pulse.LCHalt[channel] == 1 then --* Do Nothing Note will not stop        
    else
        apu_Pulse.LCTimer[channel] = apu_Pulse.LCTimer[channel] + (dt * 100)
        if apu_Pulse.LCTimer[channel] > apu_Pulse.LCTimerLength[channel] then
            apu_Pulse.StopPulseNote(channel)
        end
    end
    require('jit').on()
end

--# Pulse Channel Volume Envelope Update
function EnvelopeUpdate(channel, dt)
    require('jit').off()
    if apu_Pulse.constVolume[channel] == 0 then
        apu_Pulse.elapsedTime[channel] = apu_Pulse.elapsedTime[channel] + dt*20
        if apu_Pulse.elapsedTime[channel] >= (apu_Pulse.elapsedTimeLength[channel]) then
            if apu_Pulse.LCHalt[channel] == 1 then
                apu_Pulse.elapsedTime[channel] = 0
            else --* one shot
                apu_Pulse.StopPulseNote(channel)
            end
        else
            --* Optional: Fade out the volume (linear fade out)
            local fadeOutFactor = (((apu_Pulse.elapsedTimeLength[channel]) - apu_Pulse.elapsedTime[channel]) / (apu_Pulse.elapsedTimeLength[channel]))
            local newVolume = 0x09 * fadeOutFactor
            if newVolume > 0 then
                apu_Pulse.AdjustVolume(channel, newVolume)
            end
        end
    else
        --* Playing Sound at Constant Volume
    end
    require('jit').on()
end

--# Pulse Channel Sweep Update 
function SweepUpdate(channel, dt)
    require('jit').off()
    if apu_Pulse.sweepEnabled[channel] and (apu_Pulse.sweepPeriod[channel] ~= 0 or apu_Pulse.sweepShift[channel] > 0) then
        apu_Pulse.sweepElapsedTime[channel] = apu_Pulse.sweepElapsedTime[channel] + dt*80
        local noteToPlay = nil
        if apu_Pulse.sweepElapsedTime[channel] >= apu_Pulse.sweepPeriod[channel]+1 then
            apu_Pulse.sweepElapsedTime[channel] = 0
            if apu_Pulse.sweepNegate[channel] then
                noteToPlay = apu_Pulse.playingNote[channel] + (8-apu_Pulse.sweepShift[channel])
            else
                noteToPlay = apu_Pulse.playingNote[channel] - (8-apu_Pulse.sweepShift[channel])
            end
            if noteToPlay >= 30 and noteToPlay <= maxNoteHeight then
                if noteToPlay < maxNoteHeight then
                    apu_Pulse.PlayPulseNote(channel, noteToPlay, apu_Pulse.volume[channel], apu_Pulse.dutyCycle[channel])
                else
                    apu_Pulse.StopPulseNote(channel)
                end
            else
                apu_Pulse.StopPulseNote(channel)
            end
        end
    end
    require('jit').on()
end

--# Update Pulse Channels
function apu_Pulse.UpdatePulse(channel, dt)
    if apu_Pulse.isNotePlaying[channel] == false then return end
    LengthUpdate(channel, dt)
    EnvelopeUpdate(channel,dt)
    SweepUpdate(channel, dt)
end

--# Handle Pulse Channels
function apu_Pulse.HandlePulse(channel, addr, data)
    local baseAddr = channel == 1 and 0x4000 or 0x4004
    local pulseOffset = addr - baseAddr
    if pulseOffset == 0 then
        --% Pulse Channel Duty Cycle, Length Counter and Volume Envelope
        apu_Pulse.dutyCycle[channel] = bit.rshift(bit.band(data, 0xC0), 6)
        apu_Pulse.LCHalt[channel] = bit.rshift(bit.band(data, 0x20), 5)
        apu_Pulse.constVolume[channel] = bit.rshift(bit.band(data, 0x10), 4)
        apu_Pulse.volume[channel] = bit.band(data, 0x0F)
        apu_Pulse.elapsedTimeLength[channel] = apu_Pulse.volume[channel] + 1
        apu_Pulse.AdjustVolume(channel, apu_Pulse.volume[channel]) 
        if apu_Pulse.apuDebug[channel] then 
            print("0x4000 "..channel.." data "..numToBinary(data).." dutyCycle "..apu_Pulse.dutyCycle[channel].." LCHalt "..
            apu_Pulse.LCHalt[channel].." constVolume1 "..apu_Pulse.constVolume[channel].." pulseVolume1 "..apu_Pulse.volume[channel])
        end
    elseif pulseOffset == 1 then
        --% Pulse Channel Sweep Enabled Period Negative and Counter
        apu_Pulse.sweepEnabled[channel] = bit.band(data, 0x80) ~= 0
        apu_Pulse.sweepPeriod[channel] = bit.rshift(bit.band(data, 0x70), 4)
        apu_Pulse.sweepNegate[channel] = bit.band(data, 0x08) ~= 0
        apu_Pulse.sweepShift[channel] = bit.band(data, 0x07)
        apu_Pulse.sweepCounter[channel] = apu_Pulse.sweepPeriod[channel]
        if apu_Pulse.apuDebug[channel] then
            print("0x4001 "..channel.." data "..numToBinary(data).." sweepenabled ",
            apu_Pulse.sweepEnabled[channel]," sweepperiod "..apu_Pulse.sweepPeriod[channel].." sweepNegative ",apu_Pulse.sweepNegate[channel]," sweepshift "..
            apu_Pulse.sweepShift[channel].." swiftCounter "..apu_Pulse.sweepCounter[channel]) 
        end
    elseif pulseOffset == 2 then
        --% Pulse Channel Timer Low
        apu_Pulse.timerValue[channel] = bit.band(apu_Pulse.timerValue[channel], 0x700)
        apu_Pulse.timerValue[channel] = bit.bor(apu_Pulse.timerValue[channel], data)
        --& Calculate frequency and Play Note
        local frequency = 1789773 / (16 * (apu_Pulse.timerValue[channel] + 1))
        local noteToPlay = pulseSource.FindClosestFrequencyIndex(frequency)
        apu_Pulse.PlayPulseNote(channel, noteToPlay, apu_Pulse.volume[channel], apu_Pulse.dutyCycle[channel])
        if apu_Pulse.apuDebug[channel] then
            print("0x4002 "..channel.." data "..numToBinary(data).." TimerValue "..apu_Pulse.timerValue[channel])
        end
    elseif pulseOffset == 3 then
        --% Pulse Channel Timer High
        apu_Pulse.timerValue[channel] = bit.band(apu_Pulse.timerValue[channel], 0xFF)
        apu_Pulse.timerValue[channel] = bit.bor(apu_Pulse.timerValue[channel], bit.lshift(bit.band(data, 0x07), 8))
        apu_Pulse.LCTimerLength[channel] = lengthTable[bit.rshift(data, 3)]
        --& Calculate frequency and Play Note
        local frequency = 1789773 / (16 * (apu_Pulse.timerValue[channel] + 1))
        local noteToPlay = pulseSource.FindClosestFrequencyIndex(frequency)
        apu_Pulse.PlayPulseNote(channel, noteToPlay, apu_Pulse.volume[channel], apu_Pulse.dutyCycle[channel])
        if apu_Pulse.apuDebug[channel] then
            print("0x4003 "..channel.." data "..numToBinary(data).. " TimerValue "..
            apu_Pulse.timerValue[channel].." frequency "..frequency.." midi "..noteToPlay.." timeoutLength "..apu_Pulse.LCTimerLength[channel])
        end
    end
end
return apu_Pulse
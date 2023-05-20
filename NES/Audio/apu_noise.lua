

local apu_Noise = {}

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

--* Noise Sound Sources
local noiseSources = require("NES.Audio.noiseGenerator")

--% Noise Variable Setup
apu_Noise.MainVolume = .025
apu_Noise.apuDebug = false
apu_Noise.playingNote = 0x05
apu_Noise.timerValue = 5
apu_Noise.infPlay = 0
apu_Noise.constVolume = 0
apu_Noise.volume = 1
apu_Noise.noiseMode = 0
apu_Noise.elapsedTime = 0
apu_Noise.timeoutLength = 0
apu_Noise.playingNoiseMode = 0

--# Stop the noise channel
function apu_Noise.StopNoise()
    noiseSources[apu_Noise.playingNoiseMode][apu_Noise.playingNote]:setVolume(0)
    noiseSources[apu_Noise.playingNoiseMode][apu_Noise.playingNote]:stop()
end

--# Adjust the volume of the noise channel
function apu_Noise.AdjustVolume(volume)
    noiseSources[apu_Noise.playingNoiseMode][apu_Noise.playingNote]:setVolume(volume * VolumeMulti * apu_Noise.MainVolume)
end

--# Play the noise channel
function apu_Noise.PlayNoise(note, volume)
    if apu_Noise.apuDebug then print("PLAYING NOTE:"..note.." volume "..volume * apu_Noise.MainVolume) end
    apu_Noise.elapsedTime = 0
    noiseSources[apu_Noise.playingNoiseMode][apu_Noise.playingNote]:setVolume(0)
    noiseSources[apu_Noise.playingNoiseMode][apu_Noise.playingNote]:stop()
    --* Calculate the playback rate based on the timer value and CPU clock
    noiseSources[apu_Noise.noiseMode][note]:setVolume(volume * VolumeMulti * apu_Noise.MainVolume)
    noiseSources[apu_Noise.noiseMode][note]:play()
    apu_Noise.playingNote = note
    apu_Noise.playingNoiseMode = apu_Noise.noiseMode
end

--# Update the noise channel
function apu_Noise.UpdateNoise(dt)
    if apu_Noise.infPlay == 0 then
        apu_Noise.elapsedTime = apu_Noise.elapsedTime + dt*50
        if apu_Noise.elapsedTime >= apu_Noise.timeoutLength then
            --* Stop the noise
            apu_Noise.StopNoise()
        elseif apu_Noise.constVolume == 0 then
            --* Optional: Fade out the volume (linear fade out)
            local fadeOutFactor = 1 - (apu_Noise.elapsedTime / apu_Noise.timeoutLength)
            local newVolume = apu_Noise.volume * fadeOutFactor
            apu_Noise.AdjustVolume(newVolume)
        end
    end
end

--# Handle the noise channel
--TODO Initial Noise Setup Will Need more work to get it to work properly
function apu_Noise.HandleNoise(addr, data)
    local baseAddr = 0x400C
    local noiseOffset = addr - baseAddr
    if noiseOffset == 0 then --400C
        --% Noise Channel Length Control and Volume Control
        apu_Noise.infPlay = bit.rshift(bit.band(data, 0x20), 5)
        apu_Noise.constVolume = bit.rshift(bit.band(data, 0x10), 4)
        apu_Noise.volume = bit.band(data, 0x0F) / 0x0F0
        if apu_Noise.volume > 0 and apu_Noise.volume < .5 then apu_Noise.volume = apu_Noise.volume * 20 end
        apu_Noise.volume = apu_Noise.volume * VolumeMulti * apu_Noise.MainVolume
        apu_Noise.AdjustVolume(apu_Noise.volume)
        if apu_Noise.apuDebug then
            print("0x400C data "..numToBinary(data).." infPlay "..apu_Noise.infPlay.." constVolume "..apu_Noise.constVolume.." volume "..apu_Noise.volume)
        end
    elseif noiseOffset == 1 then -- 400D
        --% Noise channel Unused
    elseif noiseOffset == 2 then -- 400E
        --% Noise timer Period and Mode
        apu_Noise.timerValue = bit.band(data, 0x0F)+1
        apu_Noise.noiseMode = bit.rshift(bit.band(data, 0x80), 7)
        if apu_Noise.apuDebug then
            print("0x400E data "..numToBinary(data).." TimerValue "..apu_Noise.timerValue.." noiseMode "..apu_Noise.noiseMode)
        end
    elseif noiseOffset == 3 then -- 400F
        ---% Length Counter Load and Envelope Restart
        apu_Noise.timeoutLength = bit.rshift(bit.band(data, 0xF8), 3)
        if apu_Noise.volume == 0 then apu_Noise.volume = .3 * VolumeMulti * apu_Noise.MainVolume end
        apu_Noise.PlayNoise(apu_Noise.timerValue, apu_Noise.volume)
        if apu_Noise.apuDebug then
            print("0x400F data "..numToBinary(data).." timeoutLength "..apu_Noise.timeoutLength.." Noise "..apu_Noise.timerValue)
        end
    end
end

return apu_Noise

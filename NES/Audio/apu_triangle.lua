local lengthTable = require("NES.Audio.lengthcounter").LoadCounterTable()

local apu_Triangle = {}

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

--* Triangle Sound Sources
local triangleSource = require("NES.Audio.triangleGenerator")

--% Triangle Variables
apu_Triangle.MainVolume = .12
apu_Triangle.apuDebug = false
apu_Triangle.playingNote = 69
apu_Triangle.playingDutyCycle = 0
apu_Triangle.timerValue = 0
apu_Triangle.dutyCycle = 0
apu_Triangle.infPlay = 0
apu_Triangle.constVolume = 0
apu_Triangle.volume = .5
apu_Triangle.elapsedTime = 0
apu_Triangle.timeoutLength = 0
apu_Triangle.linearCounter = 0
apu_Triangle.isNotePlaying = false

--# Stop the triangle channel
function apu_Triangle.StopTriangle()
    triangleSource[apu_Triangle.playingNote]:stop()
    apu_Triangle.isNotePlaying = false
end

--# Adjust the volume of the triangle channel
function apu_Triangle.AdjustVolume(volume)
    local setVolume = volume * apu_Triangle.MainVolume * VolumeMulti
    triangleSource[apu_Triangle.playingNote]:setVolume(setVolume)
end

--# Play the triangle channel
function apu_Triangle.PlayTriangle(note, volume)
    if note < 4 and apu_Triangle.isNotePlaying then apu_Triangle.StopTriangle() return end
    apu_Triangle.elapsedTime = 0
    if apu_Triangle.playingNote ~= note or apu_Triangle.isNotePlaying == false then
        --print("playing Note ", note)
        apu_Triangle.StopTriangle()
        if note > 300 then return end
        apu_Triangle.playingNote = note
        apu_Triangle.isNotePlaying = true
        apu_Triangle.AdjustVolume(apu_Triangle.MainVolume)
        triangleSource[note]:play()
    end
end

--# Update the triangle channel
function apu_Triangle.UpdateTriangle(dt)
    if apu_Triangle.infPlay == 0 then
        apu_Triangle.elapsedTime = apu_Triangle.elapsedTime + dt*80
        if apu_Triangle.elapsedTime >= apu_Triangle.timeoutLength then
            -- Stop the note
            apu_Triangle.StopTriangle()
        end
    end
    if apu_Triangle.linearCounter > 0 then
        apu_Triangle.linearCounter = apu_Triangle.linearCounter - 1
    else
        apu_Triangle.StopTriangle()
    end
end

--# Handle the triangle channel
function apu_Triangle.HandleTriangle(addr, data)
    local baseAddr = 0x4008
    local triangleOffset = addr - baseAddr
    if triangleOffset == 0 then
        --% Set Linear Counter and Infanite Play
        apu_Triangle.linearCounter = bit.band(data, 0x7F) --* Update the linear counter
        apu_Triangle.infPlay = bit.rshift(bit.band(data, 0x80), 7)
        if apu_Triangle.apuDebug then
            print("0x4008 data "..numToBinary(data).." linearCounter "..apu_Triangle.linearCounter.." infPlay "..apu_Triangle.infPlay.." constVolume "..apu_Triangle.constVolume.." volume "..apu_Triangle.volume)
        end
    elseif triangleOffset == 1 then
        --% Triangle channel unused
    elseif triangleOffset == 2 then
        --% Change Note Value Low
        apu_Triangle.timerValue = bit.band(apu_Triangle.timerValue, 0x700)
        apu_Triangle.timerValue = bit.bor(apu_Triangle.timerValue, data)
        --& Calculate frequency and Play Note
        local frequency = 1789773 / (32 * (apu_Triangle.timerValue + 1))
        local noteToPlay = triangleSource.FindClosestFrequencyIndex(frequency)
        apu_Triangle.PlayTriangle(noteToPlay, apu_Triangle.volume)
        if apu_Triangle.apuDebug then
            print("0x400A data "..numToBinary(data).." TimerValue "..apu_Triangle.timerValue)
        end
    elseif triangleOffset == 3 then
        --% Change Note Value High
        apu_Triangle.timerValue = bit.band(apu_Triangle.timerValue, 0xFF)
        apu_Triangle.timerValue = bit.bor(apu_Triangle.timerValue, bit.lshift(bit.band(data, 0x07), 8))
        apu_Triangle.timeoutLength = lengthTable[bit.rshift(data, 3)]
        --& Calculate frequency and Play Note
        local frequency = 1789773 / (32 * (apu_Triangle.timerValue + 1))
        local noteToPlay = triangleSource.FindClosestFrequencyIndex(frequency)
        apu_Triangle.PlayTriangle(noteToPlay, apu_Triangle.volume)
        if apu_Triangle.apuDebug then
            print("0x400B data "..numToBinary(data).." TimerValue "..apu_Triangle.timerValue.." frequency "..frequency.." midi "..noteToPlay.." timeoutLength "..apu_Triangle.timeoutLength)
        end
    end
end

return apu_Triangle
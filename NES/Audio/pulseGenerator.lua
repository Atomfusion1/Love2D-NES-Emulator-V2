print("Setting Up Pulse Sound Table This Might Take a Second")

--& NES Pulse Channel Notes to Create
local frequencyTable = {}
local A4 = 440.00
for n = 0.5, 128, 0.5 do -- From C0 to B9, with intermediate steps
    table.insert(frequencyTable, A4 * 2^((n-69)/12))
end

-- Pulse Wave Settings
local sampleRate = 44100
local amplitude = .5
local duration = 0.5
local dutyCycles = {0.125, 0.25, 0.5, 0.80}
local pulseSource = {}

--# Generate Square Wave Table
local function generateSquareWave(sampleRate, frequency, amplitude, duration, dutyCycle)
    local samplePoints = math.floor(sampleRate * duration)
    local soundData = love.sound.newSoundData(samplePoints, sampleRate, 16, 1)

    for i = 0, samplePoints - 1 do
        local time = i / sampleRate
        local sinValue = math.sin(2 * math.pi * frequency * time)
        local value = (sinValue >= dutyCycle * 2 - 1) and amplitude or -amplitude
        soundData:setSample(i, value)
    end
    return soundData
end

--# Pulse Source for 2 Channels each having 4 Duty Cycles and 254 channels .5 midi 
for l = 1, 2 do
    pulseSource[l] = {}
    for i, note in ipairs(frequencyTable) do
        pulseSource[l][i] = {}
        for j = 0, #dutyCycles - 1 do
            local dutyCycle = dutyCycles[j + 1]
            local soundData = generateSquareWave(sampleRate, note, amplitude, duration, dutyCycle)
            pulseSource[l][i][j] = love.audio.newSource(soundData, "static")
            pulseSource[l][i][j]:setLooping(true)
        end
    end
end

--# Find the closest frequency in the frequency table
function pulseSource.FindClosestFrequencyIndex(targetFrequency)
    local closestIndex = 1
    local closestDifference = math.abs(targetFrequency - frequencyTable[1])
    for i = 2, #frequencyTable do
        local difference = math.abs(targetFrequency - frequencyTable[i])
        if difference < closestDifference then
            closestIndex = i
            closestDifference = difference
        end
    end
    return closestIndex
end

return pulseSource
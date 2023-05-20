print("Setting Up Triangle Sound Table This Might Take a Second")

--& NES Pulse Channel Notes to Create
local frequencyTable = {}
local A4 = 440.00
for n = 0.5, 190, 0.5 do -- From C0 to B9, with intermediate steps
    table.insert(frequencyTable, A4 * 2^((n-69)/12))
end

--% Triangle Wave Settings
local quantizationLevels = 32  -- Adjust this value to control the quantization
local sampleRate = 44100
local amplitude = .5
local triangleSource = {}

--& Of all ways to calculate a Triangle Wave This produces the Least amount of PoPs .. Fuck if i know why 
local function generateTriangleWaveCycles(sampleRate, frequency, amplitude, cycles)
    local samplesPerCycle = sampleRate / frequency
    local samplePoints = math.floor(samplesPerCycle * cycles)
    local soundData = love.sound.newSoundData(samplePoints, sampleRate, 16, 1)
    for i = 0, samplePoints - 1 do
        local time = i / sampleRate
        local value = ((time * frequency) % 1) * 4 - 2
        if value > 1 then
            value = 2 - value
        elseif value < -1 then
            value = -2 - value
        end
        value = math.floor(value * quantizationLevels + 0.5) / quantizationLevels
        value = value * amplitude
        soundData:setSample(i, value)
    end
    return soundData
end

--# Triangle Source
for i, note in ipairs(frequencyTable) do
    local soundData = generateTriangleWaveCycles(sampleRate, note, amplitude, 20)
    triangleSource[i] = love.audio.newSource(soundData, "static")
    triangleSource[i]:setPitch(1)
    triangleSource[i]:setLooping(true)
end

--# Find the closest frequency in the frequency table
function triangleSource.FindClosestFrequencyIndex(targetFrequency)
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

return triangleSource
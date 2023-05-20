print("Setting Up Noise Table This Might Take a Second")

--# Generate Noise in a Sine Wave
local function generateSineWithNoise(frequency, numSamples, sampleRate, noiseAmplitude, mode)
    local samples = {}
    local noiseValue = 1
    for i = 1, numSamples do
        local t = (i - 1) / sampleRate
        local sineValue = 2*math.sin(frequency * t)
        if mode == 0 then
            noiseValue = love.math.random(2) == 1 and 1 or -1
        else
            noiseValue = 1
        end
        samples[i] = sineValue * noiseValue
    end
    return samples
end

--# Convert Samples to SoundData
local function samplesToSoundData(samples, sampleRate)
    local data = love.sound.newSoundData(#samples, sampleRate, 16, 1)
    for i = 1, #samples do
        data:setSample(i - 1, samples[i])
    end
    return data
end

--# Create Noise Source
local function createNoiseSource(frequency, numSamples, sampleRate, noiseAmplitude, mode)
    local samples = generateSineWithNoise(frequency, numSamples, sampleRate, noiseAmplitude, mode)
    local soundData = samplesToSoundData(samples, sampleRate)
    local noiseSource = love.audio.newSource(soundData, "static")
    noiseSource:setLooping(true)
    return noiseSource
end

--* Noise Settings
local ntscFrequencies = {
    4811.2, 2405.6, 1202.8, 601.4, 300.7, 200.5, 150.4,
    120.3, 95.3, 75.8, 50.6, 37.9,25.3,18.9,9.5,4.7
}
local sampleRate = {
    447443, 223721, 111860, 55930, 27965, 18643, 13982,
    11186, 8860, 7046, 4709, 3523, 2348, 1761, 879, 440
}
local duration = .5 -- in seconds
local noiseAmplitude = 1

--# Create Sound Samples and Store in noiseSources
local noiseSources = {}
for l = 0, 1 do
    noiseSources[l] = {}
    for i = 1, #ntscFrequencies do
        noiseSources[l] [i] = createNoiseSource(ntscFrequencies[i], sampleRate[i] * duration, sampleRate[i], noiseAmplitude, l)
        noiseSources[l] [i]:setLooping(true)
    end
end

return noiseSources
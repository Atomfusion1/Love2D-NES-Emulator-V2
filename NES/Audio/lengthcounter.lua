local lengthCounter = {}

--# Length Counter Table for Square 1 and 2 turn off sound after a certain number of cycles
function lengthCounter.LoadCounterTable()
    return {
        [0x00] = 10,
        [0x01] = 254,
        [0x02] = 20,
        [0x03] = 2,
        [0x04] = 40,
        [0x05] = 4,
        [0x06] = 80,
        [0x07] = 6,
        [0x08] = 160,
        [0x09] = 8,
        [0x0a] = 60,
        [0x0b] = 10,
        [0x0c] = 14,
        [0x0d] = 12,
        [0x0e] = 26,
        [0x0f] = 14,
        [0x10] = 12,
        [0x11] = 16,
        [0x12] = 24,
        [0x13] = 18,
        [0x14] = 48,
        [0x15] = 20,
        [0x16] = 96,
        [0x17] = 22,
        [0x18] = 192,
        [0x19] = 24,
        [0x1a] = 72,
        [0x1b] = 26,
        [0x1c] = 16,
        [0x1d] = 28,
        [0x1e] = 32,
        [0x1f] = 30,
    }
end

return lengthCounter
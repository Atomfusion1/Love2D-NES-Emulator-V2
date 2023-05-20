local ppuIO = {}


-- PPU IO Control
ppuIO.bit_masks = {
    bit0 = 1,
    bit1 = 2,
    bit2 = 4,
    bit3 = 8,
    bit4 = 16,
    bit5 = 32,
    bit6 = 64,
    bit7 = 128,
}
    -- Create a new value variable and set its metatable
ppuIO.CTRL    = 0x90
ppuIO.MASKS   = 0x00
ppuIO.STATUS  = 0x80
ppuIO.OAMADDR = 0x0000
ppuIO.OAMDATA = 0x00
ppuIO.SCROLL  = 0x00
ppuIO.ADDR    = 0x00
ppuIO.DATA    = 0x00
ppuIO.OAMDMA  = 0x00

local bit = require("bit")
-- Pass Value and #Bit to get if high / low 
function ppuIO.IsBitSet(value, bitPosition)
    -- Shift 1 to the left by the bit position, and AND it with the value
    -- to get the value of that bit. If the result is non-zero, the bit is set.
    return bit.band(value, bit.lshift(1, bitPosition)) ~= 0
end
-- set bit value value #bit true/false
function ppuIO.SetBit(value, bitPosition, isSet)
    -- Shift 1 to the left by the bit position to get a mask with a 1 in that bit.
    local mask = bit.lshift(1, bitPosition)
    if isSet then
        -- OR the value with the mask to set the bit.
        value = bit.bor(value, mask)
    else
        -- AND the value with the inverse of the mask to clear the bit.
        value = bit.band(value, bit.bnot(mask))
    end
    return value
end

ppuIO.NameTableAddress = 0x00
ppuIO.BackgroundTable = 0x00
ppuIO.SpriteTable = 0x00


-- Return the PPU control registers table
return ppuIO


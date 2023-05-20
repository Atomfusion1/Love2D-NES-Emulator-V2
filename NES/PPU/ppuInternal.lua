
local band, lshift, rshift, bor  = bit.band, bit.lshift, bit.rshift, bit.bor
local ppuInternal = {}
ppuInternal.scanLines       = 0
ppuInternal.scanLinePixels  = 0
ppuInternal.inVBlank        = false
ppuInternal.UpdateScreen    = false
ppuInternal.ScreenArray     = {}

for i = 0, 245759, 4 do -- Setup for Crash 
    ppuInternal.ScreenArray[i+0] = 0x30
    ppuInternal.ScreenArray[i+1] = 0x00
    ppuInternal.ScreenArray[i+2] = 0x00
    ppuInternal.ScreenArray[i+3] = 0xFF
end

-- This kinda Sucks to do this way but This is far faster then using bit.band some of these values we will call 
-- 250000 timers per frame 
ppuInternal.PPUCTRL = {
    value           = 0x80,
    BaseName1       = 0,
    BaseName2       = 0,
    VRAMInc         = 0,
    SpriteTable     = 0,
    BackgroundTable = 0,
    SpriteSize      = 0,
    PPUMaster       = 0,
    NMIGenerate     = 1,
}
ppuInternal.PPUMASK = {
    value       = 0x00,
    greyscale   = 0,
    showLeftBack8  = 0,
    showLeftSprit8 = 0,
    showBackground  = 0,
    showSprites     = 0,
    EmphasizeRed    = 0,
    EmphasizeGreen  = 0,
    EmphasizeBlue   = 0,
}
ppuInternal.PPUSTATUS = {
    value           = 0x00,
    VBlankStart     = 0,
    Sprite0Hit      = 0,
    SpriteOverflow  = 0,
}
ppuInternal.OAMADDR     = 0x00
ppuInternal.OAMDATA     = 0x00
ppuInternal.PPUSCROLL   = 0x0000
ppuInternal.OAMDMA      = 0x00

function ppuInternal.WriteValueToPPUCTRL(value)
    ppuInternal.PPUCTRL.value           = value
    ppuInternal.PPUCTRL.BaseName1       = (band(value, 0x01) ~= 0) and 1 or 0
    ppuInternal.PPUCTRL.BaseName2       = (band(value, 0x02) ~= 0) and 1 or 0
    ppuInternal.PPUCTRL.VRAMInc         = (band(value, 0x04) ~= 0) and 1 or 0
    ppuInternal.PPUCTRL.SpriteTable     = (band(value, 0x08) ~= 0) and 1 or 0
    ppuInternal.PPUCTRL.BackgroundTable = (band(value, 0x10) ~= 0) and 1 or 0
    ppuInternal.PPUCTRL.SpriteSize      = (band(value, 0x20) ~= 0) and 1 or 0
    ppuInternal.PPUCTRL.PPUMaster       = (band(value, 0x40) ~= 0) and 1 or 0
    ppuInternal.PPUCTRL.NMIGenerate     = (band(value, 0x80) ~= 0) and 1 or 0
end

function ppuInternal.WriteValueToMASK(value)
    ppuInternal.PPUMASK.value               = value
    ppuInternal.PPUMASK.greyscale           = (band(value, 0x01) ~= 0) and 1 or 0
    ppuInternal.PPUMASK.showLeftBack8       = (band(value, 0x02) ~= 0) and 1 or 0
    ppuInternal.PPUMASK.showLeftSprit8      = (band(value, 0x04) ~= 0) and 1 or 0
    ppuInternal.PPUMASK.showBackground      = (band(value, 0x08) ~= 0) and 1 or 0
    ppuInternal.PPUMASK.showSprites         = (band(value, 0x10) ~= 0) and 1 or 0
    ppuInternal.PPUMASK.EmphasizeRed        = (band(value, 0x20) ~= 0) and 1 or 0
    ppuInternal.PPUMASK.EmphasizeGreen      = (band(value, 0x40) ~= 0) and 1 or 0
    ppuInternal.PPUMASK.EmphasizeBlue       = (band(value, 0x80) ~= 0) and 1 or 0
end

function ppuInternal.GetValueOfPPUSTATUS()
    local value = 0
    value = bor(value, ppuInternal.PPUSTATUS.VBlankStart * 0x80) -- Set vertical blank flag
    value = bor(value, ppuInternal.PPUSTATUS.Sprite0Hit * 0x40) -- Set sprite 0 hit flag
    --value = bor(value, ppuInternal.PPUSTATUS.SpriteOverflow * 0x20) -- Set sprite overflow flag
    return value
end

-- function to read the value of a bit
function ppuInternal.ReadBitValue(var, bitnum)
    return band(rshift(var,bitnum), 1)
end

-- function to set the value of a bit in a variable
function ppuInternal.SetBitValue(var, bitnum, value)
    local mask = bit.lshift(1, bitnum)
    if value == 0 then
        mask = bit.bnot(mask)
        var = bit.band(var, mask)
    else
        var = bit.bor(var, mask)
    end
    return var
end

return ppuInternal
--TODO This is the Loopy Correct Implimentation that I need to Switch to Will fix Super Mario Bros

local loopy = {}
loopy.w = {}
loopy.fine_x = 0x00

local function create_loopy_register()
    local loopy_register = {
        reg = 0x000
    }

    local loopy_register_mt = {
        __index = function(t, k)
            if k == "coarse_x" then
                return bit.band(t.reg, 0x001F)
            elseif k == "coarse_y" then
                return bit.rshift(bit.band(t.reg, 0x03E0), 5)
            elseif k == "nametable_x" then
                return bit.rshift(bit.band(t.reg, 0x0400), 10)
            elseif k == "nametable_y" then
                return bit.rshift(bit.band(t.reg, 0x0800), 11)
            elseif k == "fine_y" then
                return bit.rshift(bit.band(t.reg, 0x7000), 12)
            elseif k == "unused" then
                return bit.rshift(bit.band(t.reg, 0x8000), 15)
            end
        end,
        __newindex = function(t, k, v)
            if k == "coarse_x" then
                t.reg = bit.bor(bit.band(t.reg, 0xFFE0), v)
            elseif k == "coarse_y" then
                t.reg = bit.bor(bit.band(t.reg, 0xFC1F), bit.lshift(v, 5))
            elseif k == "nametable_x" then
                t.reg = bit.bor(bit.band(t.reg, 0xFBFF), bit.lshift(v, 10))
            elseif k == "nametable_y" then
                t.reg = bit.bor(bit.band(t.reg, 0xF7FF), bit.lshift(v, 11))
            elseif k == "fine_y" then
                t.reg = bit.bor(bit.band(t.reg, 0x8FFF), bit.lshift(v, 12))
            elseif k == "unused" then
                t.reg = bit.bor(bit.band(t.reg, 0x7FFF), bit.lshift(v, 15))
            end
        end
    }
    setmetatable(loopy_register, loopy_register_mt)
    return loopy_register
end

loopy.vram_addr = create_loopy_register()
loopy.tram_addr = create_loopy_register()
loopy.vram_addr.reg = 0x1000
loopy.tram_addr.reg = 0x1000



return loopy
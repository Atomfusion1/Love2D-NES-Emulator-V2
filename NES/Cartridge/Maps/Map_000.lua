local cart = require("NES.Cartridge.Cartridge")

local mapper = {}
mapper.version = 0x00
local CHRoffset = nil
local functionRead = nil
local ROM = nil

function mapper.CPURead(addr)
    if functionRead(addr) == nil then print("Boom", string.format("%x",addr)) return 0 end
    return functionRead(addr)
end

function mapper.CPUWrite(addr, value)

end


    -- Character Memory 
function mapper.PPURead(addr)
    return ROM[addr + CHRoffset]
end

function mapper.PPUWrite(addr, value)

end

function mapper.INI()
    cart.Mirror = bit.band(cart.header[0x06], 0x01) == 1 and 1 or 0
    -- 0 - Horizontal Mirror
    -- 1 - Vertical Mirror
    print("mirror "..cart.Mirror)
    print("mapper initialized Mirror State "..cart.Mirror)
    CHRoffset = cart.header[0x04]*0x4000 + 0x0010 -- offset for header added back on 
    ROM = cart.ROM
    if cart.header[0x04] == 1 then
        functionRead = function(addr)
            if addr >= 0xC000 and addr <= 0xFFFF then
                return cart.ROM[addr - 0xC000 + 0x0010] -- offset for header added back on 
            elseif addr >= 0x8000 and addr <= 0xFFFF then
                return cart.ROM[addr - 0x8000 + 0x0010] -- offset for header added back on 
            elseif addr >= 0x4020 and addr <= 0x7FFF then
                print(string.format("Write to Rom %x",(addr - 0x4000 + 0x0010)))
                return 0 -- Ice Climber hack atm 
            end
        end
    else
        functionRead = function(addr)
            return ROM[addr - 0x7FF0]
        end
    end
end

return mapper
local cart        = require("NES.Cartridge.Cartridge")

local nameTable = {}

nameTable.tblName    = {
    [0] = {},
    [1] = {}
}
nameTable.tblPalette = {}
-- Extra Feature Future 
nameTable.tblPattern = {
    [0] = {},
    [1] = {}
}
nameTable.nTX       = 1
nameTable.nTY       = 1
nameTable.courseX   = 0
nameTable.courseY   = 0
nameTable.fineX     = 0
nameTable.fineY     = 0

-- Initialize the arrays
for i = 0, 0x0400 do
    nameTable.tblName[0][i] = 0x00
    nameTable.tblName[1][i] = 0x00
end
-- Palette Table 
for i = 0, 0x20 do
    nameTable.tblPalette[i] = love.math.random(0,40)
end

-- Initialize Pattern Tables 
for i = 0, 0x1000 do
    nameTable.tblName[0][i] = 0x00
    nameTable.tblName[1][i] = 0x00
end


function nameTable.NameTableMirrorRead(addr)
    addr = bit.band(addr,0x0FFF)
    local data
    -- Vertical
    if cart.Mirror == 1 then
        if addr >= 0x0000 and addr <= 0x03FF then
            data = nameTable.tblName[0][bit.band(addr,0x03FF)]
            return data
        elseif addr >= 0x0400 and addr <= 0x07FF then
            data = nameTable.tblName[1][bit.band(addr,0x03FF)]
            return data
        elseif addr >= 0x0800 and addr <= 0x0BFF then
            data = nameTable.tblName[0][bit.band(addr,0x03FF)]
            return data
        elseif addr >= 0x0C00 and addr <= 0x0FFF then
            data = nameTable.tblName[1][bit.band(addr,0x03FF)]
            return data
        end
        -- Horizontal
    elseif cart.Mirror == 0 then
        if addr >= 0x0000 and addr <= 0x03FF then
            data = nameTable.tblName[0][bit.band(addr,0x03FF)]
            return data
        elseif addr >= 0x0400 and addr <= 0x07FF then
            data = nameTable.tblName[0][bit.band(addr,0x03FF)]
            return data
        elseif addr >= 0x0800 and addr <= 0x0BFF then
            data = nameTable.tblName[1][bit.band(addr,0x03FF)]
            return data
        elseif addr >= 0x0C00 and addr <= 0x0FFF then
            data = nameTable.tblName[1][bit.band(addr,0x03FF)]
            return data
        end
    elseif cart.Mirror == 2 then
        if addr >= 0x0000 and addr <= 0x03FF then
            data = nameTable.tblName[0][bit.band(addr,0x03FF)]
            return data
        elseif addr >= 0x0400 and addr <= 0x07FF then
            data = nameTable.tblName[0][bit.band(addr,0x03FF)]
            return data
        elseif addr >= 0x0800 and addr <= 0x0BFF then
            data = nameTable.tblName[0][bit.band(addr,0x03FF)]
            return data
        elseif addr >= 0x0C00 and addr <= 0x0FFF then
            data = nameTable.tblName[0][bit.band(addr,0x03FF)]
            return data
        end
    elseif cart.Mirror == 3 then
        if addr >= 0x0000 and addr <= 0x03FF then
            data = nameTable.tblName[1][bit.band(addr,0x03FF)]
            return data
        elseif addr >= 0x0400 and addr <= 0x07FF then
            data = nameTable.tblName[1][bit.band(addr,0x03FF)]
            return data
        elseif addr >= 0x0800 and addr <= 0x0BFF then
            data = nameTable.tblName[1][bit.band(addr,0x03FF)]
            return data
        elseif addr >= 0x0C00 and addr <= 0x0FFF then
            data = nameTable.tblName[1][bit.band(addr,0x03FF)]
            return data
        end
    end
    print("Name Table Read Failed ", addr)
    return nil
end


function nameTable.NameTableMirrorWrite(addr,data)
    addr = bit.band(addr,0x0FFF)
    -- Vertical
    if cart.Mirror == 1 then
        if addr >= 0x0000 and addr <= 0x03FF then
            nameTable.tblName[0][bit.band(addr,0x03FF)] = data
            return
        elseif addr >= 0x0400 and addr <= 0x07FF then
            nameTable.tblName[1][bit.band(addr,0x03FF)] = data
            return
        elseif addr >= 0x0800 and addr <= 0x0BFF then
            nameTable.tblName[0][bit.band(addr,0x03FF)] = data
            return
        elseif addr >= 0x0C00 and addr <= 0x0FFF then
            nameTable.tblName[1][bit.band(addr,0x03FF)] = data
            return
        end
        -- Horizontal
    elseif cart.Mirror == 0 then
        if addr >= 0x0000 and addr <= 0x03FF then
            nameTable.tblName[0][bit.band(addr,0x03FF)] = data
            --print("Nametable Write <400", bit.band(addr,0x03FF), addr, data)
            return
        elseif addr >= 0x0400 and addr <= 0x07FF then
            nameTable.tblName[0][bit.band(addr,0x03FF)] = data
            --print("Nametable Write 400<800", bit.band(addr,0x03FF), addr, data)
            return
        elseif addr >= 0x0800 and addr <= 0x0BFF then
            nameTable.tblName[1][bit.band(addr,0x03FF)] = data
            return
        elseif addr >= 0x0C00 and addr <= 0x0FFF then
            nameTable.tblName[1][bit.band(addr,0x03FF)] = data
            return
        end
    elseif cart.Mirror == 2 then -- Single Mirror = 0 All 4 First 1k
        if addr >= 0x0000 and addr <= 0x03FF then
            nameTable.tblName[0][bit.band(addr, 0x03FF)] = data
            return
        elseif addr >= 0x0400 and addr <= 0x07FF then
            nameTable.tblName[0][bit.band(addr, 0x03FF)] = data
            return
        elseif addr >= 0x0800 and addr <= 0x0BFF then
            nameTable.tblName[0][bit.band(addr, 0x03FF)] = data
            return
        elseif addr >= 0x0C00 and addr <= 0x0FFF then
            nameTable.tblName[0][bit.band(addr, 0x03FF)] = data
            return
        end
    elseif cart.Mirror == 3 then -- Single Mirror = 1 All 4 Second 1k
        if addr >= 0x0000 and addr <= 0x03FF then
            nameTable.tblName[1][bit.band(addr, 0x03FF)] = data
            return
        elseif addr >= 0x0400 and addr <= 0x07FF then
            nameTable.tblName[1][bit.band(addr, 0x03FF)] = data
            return
        elseif addr >= 0x0800 and addr <= 0x0BFF then
            nameTable.tblName[1][bit.band(addr, 0x03FF)] = data
            return
        elseif addr >= 0x0C00 and addr <= 0x0FFF then
            nameTable.tblName[1][bit.band(addr, 0x03FF)] = data
            return
        end
end
    print("NameTableWrite Failed addr "..string.format("%x",addr).. "data:"..data.." mirror:".. cart.Mirror)
    return data
end

return nameTable

-- pallet table numbering byte == 4 2x2 grid
-- bits 1,0 top Right 3,2 Top Right 4,5 bottom left 6,7 bottom right 4 tiles must be same pallet (color)
-- pallet course 5 bit to 3 to get memory offset 3C0 and use the removed 2bits for location of memory tile
-- This is a tricky part to understand you will not get it till you do and when you do its not that bad 
-- see https://www.youtube.com/watch?v=-THeUXqR3zY&t=2709s&ab_channel=javidx9=2026 video

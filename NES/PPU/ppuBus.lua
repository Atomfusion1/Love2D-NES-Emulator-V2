local cart      = require("NES.Cartridge.Cartridge")
local mapper    = require("NES.Cartridge.Mappers")
local nameTable = require("NES.PPU.ppunametable")
local loopy     = require("NES.PPU.loopy")
local OAM       = require("NES.PPU.ppuOAM")
local ppuIO     = require("NES.PPU.ppuIO")

local ppuBus = {}

local debugPPU = false
local ppuaddrLatch = 0
local scrollLatch = 0
local ppu_data_buffer = 0x00
local trimaddr = 0x00
local vRamAddress = 0x00

function ppuBus.CPURead(addr)
    if addr == 0x0000 then  -- control
        if debugPPU then print("Read PPU 2000 and data ", "nil") end
        return 0x00
    elseif addr == 0x0001 then -- mask 
        if debugPPU then print("Read PPU 2001 and data ", "nil") end
        return 0x00
    elseif addr == 0x0002 then -- status 
        -- Reading Status Resets Latches and Only top 3 bits are used bottom are noise
        local data = bit.bor(bit.band(ppuIO.STATUS,0xE0),bit.band(ppu_data_buffer,0x1F))
        ppuaddrLatch = 0
        scrollLatch = 0
        ppuIO.STATUS = bit.band(ppuIO.STATUS,0x60)
        if debugPPU then print("Read PPU 2002 and data ", data) end
        return data
    elseif addr == 0x0003 then -- oam address
        local data = 0x00
        if debugPPU then print("Read PPU 2003 and data ", data) end
        return data
    elseif addr == 0x0004 then -- oam data 
        local data = 0x00
        if debugPPU then print("Read PPU 2004 and data ", data) end
        return data
    elseif addr == 0x0005 then -- scroll 
        local data = 0x00
        if debugPPU then print("Read PPU 2005 and data ", data) end
        return data
    elseif addr == 0x0006 then -- ppu address
        local data = 0x00
        if debugPPU then print("Read PPU 2006 and data ", data) end
        return data
    elseif addr == 0x0007 then -- ppu data 
        -- Delay Output from PPU one Read so store it then give it the next read
        local data = ppu_data_buffer
        ppu_data_buffer = ppuBus.PPURead(loopy.register_vram_addr)
        -- but if its palette data send right away
        if loopy.register_vram_addr >= 0x3F00 then data = ppu_data_buffer end
        -- update Pointer location         
        if ppuIO.IsBitSet(ppuIO.CTRL, 2) then
            loopy.register_vram_addr = loopy.register_vram_addr + 32
        else
            loopy.register_vram_addr = loopy.register_vram_addr + 1
        end
        if debugPPU then print("Read PPU 2007 and data ", data, ppu_data_buffer, loopy.register_vram_addr, ppuIO.IsBitSet(ppuIO.CTRL, 2)) end
        
        return data
    end
    print("PPU Read Error")
    return 0x00
end

function ppuBus.CPUWrite(addr, data)
    if addr == 0x0000 then  -- control
        ppuIO.CTRL = data
        ppuIO.NameTableAddress = bit.band(data, 0x03)
        ppuIO.BackgroundTable = bit.band(data, 0x10) ~= 0 and 1 or 0
        ppuIO.SpriteTable = bit.band(data, 0x08) ~= 0 and 1 or 0
        loopy.nametable_x = ppuIO.IsBitSet(ppuIO.CTRL, 0) and 1 or 0
        loopy.nametable_y = ppuIO.IsBitSet(ppuIO.CTRL, 1) and 1 or 0
        if debugPPU then print(string.format("Write CTRL PPU 2000 data:%x CTRL:%x NameTable:%x ScanLine ", data, ppuIO.CTRL, ppuIO.NameTableAddress),loopy.scanLine) end
    elseif addr == 0x0001 then -- mask
        ppuIO.MASKS = data
        loopy.drawScreen = bit.band(data, 0x08) ~= 0 and true or false
        loopy.drawSprites = bit.band(data, 0x10) ~= 0 and true or false
        --print(loopy.drawScreen, loopy.drawSprites)
        if debugPPU then print(string.format("Write PPU 2001 %x %x", addr, data)) end
    elseif addr == 0x0002 then -- status 
        scrollLatch = 0 -- reset address latch 
        ppuaddrLatch = 0 -- reset ppu addr latch 
        if debugPPU then print(string.format("Write PPU 2002 %x %x", addr, data)) end
        return nil
    elseif addr == 0x0003 then -- oam address
        ppuIO.OAMADDR = data
        if debugPPU then print(string.format("Write PPU 2003 %x %x", addr, data)) end
    elseif addr == 0x0004 then -- oam data 
        OAM.WriteToOAM(ppuIO, data)
        if debugPPU then print(string.format("Write PPU 2004 %x %x", addr, data)) end
    elseif addr == 0x0005 then -- scroll 
        if scrollLatch == 0 then
            ppuIO.SCROLL = data * 256
            loopy.fine_x = bit.band(data, 0x07)
            loopy.course_x = bit.rshift(data, 3)

            scrollLatch = 1
            if debugPPU then print(string.format("Write PPU 2005 1 data:%x, courseX:%x fineX:%x, courseY%x, fineY:%x", data,
                loopy.course_x, loopy.fine_x, loopy.course_y, loopy.fine_y ),loopy.scanLine) end
        else
            ppuIO.SCROLL = data + ppuIO.SCROLL
            loopy.fine_y = bit.band(data, 0x07)
            -- divide by 8
            loopy.course_y = bit.rshift(data, 3)
    --ppuIO.CTRL = bit.bor(ppuIO.CTRL, 0x80) -- Set NMI from Metroid Hack
            if loopy.course_y > 0x1D then
                loopy.course_y = loopy.course_y-0x20
            end
            scrollLatch = 0
            if debugPPU then print(string.format("Write PPU 2005 2 data:%x, courseX:%x fineX:%x, courseY%x, fineY:%x", data,
                loopy.course_x, loopy.fine_x, loopy.course_y, loopy.fine_y ),loopy.scanLine) end
        end
        if debugPPU then print(string.format("Write PPU 2005 data:%x, courseX:%x fineX:%x, courseY%x, fineY:%x", data, 
            loopy.course_x, loopy.fine_x, loopy.course_y, loopy.fine_y )) end
    elseif addr == 0x0006 then -- ppu address
        if ppuaddrLatch == 0 then
            -- shift just the top 
            trimaddr = bit.bor(bit.lshift(bit.band(data,0x3F),8), bit.band(trimaddr, 0x00FF))
            loopy.nametable_x = bit.rshift(bit.band(data,0x4), 2)
            loopy.nametable_y = bit.rshift(bit.band(data,0x8), 3)
            loopy.fine_y = bit.rshift(bit.band(data,0x30), 4)
            ppuaddrLatch = 1
            if debugPPU then print(string.format("Write PPU 2006 1 latch %x trimaddr %x data %x pointer:%04x", ppuaddrLatch, trimaddr, data, loopy.register_vram_addr)) end 
        else
            -- shift the lower 
            trimaddr = bit.bor(bit.band(trimaddr,0xFF00), data)
            loopy.register_tram_addr = trimaddr -- set oam Pointer 
            loopy.register_vram_addr = loopy.register_tram_addr
            loopy.course_x = bit.band(data,0x1F)
            ppuaddrLatch = 0
            if debugPPU then print(string.format("Write PPU 2006 2 latch %x trimaddr %x data %x pointer:%04x", ppuaddrLatch, trimaddr, data, loopy.register_vram_addr)) end 
        end
        --print(string.format("PPU %x %x", addr, data))
    elseif addr == 0x0007 then -- ppu data 
        ppuBus.PPUWrite(loopy.register_vram_addr, data)
        if ppuIO.IsBitSet(ppuIO.CTRL, 2) then
            loopy.register_vram_addr = loopy.register_vram_addr + 32
        else
            loopy.register_vram_addr = loopy.register_vram_addr + 1
        end
        if debugPPU then print(string.format("Write PPU 2007 %x, %x, %x, %s", addr, data, loopy.register_vram_addr ,tostring(ppuIO.IsBitSet(ppuIO.CTRL, 2)))) end
    elseif addr == 0x4014 then
        OAM.RefreshOAM(data, ppuIO.OAMADDR)
    end
    return
end

-- PPU Own Bus .. NOT FOR 2000-2007 Those are Mapped on the CPU to stored in internal registers location in PPU 
function ppuBus.PPURead(addr)
    -- Mirrors 0x0 - 0x3FFF
        addr = bit.band(addr, 0x3FFF)
        
        local cartMapper = mapper[cart.mapper].mapper
    -- Pattern Tables CHR ROM
        if addr >= 0x0000 and addr <= 0x1FFF then
            local value = cartMapper.PPURead(addr)
            return value
    -- Access internal NameTable Memory VRAM
        elseif addr >= 0x2000 and addr <= 0x3EFF then
            return nameTable.NameTableMirrorRead(addr)
    -- Palette Memory Palette 
        elseif addr >= 0x3F00 and addr <= 0x3FFF then
            addr = bit.band(addr,0x001F)
            if addr == 0x0010 then addr = 0x0000 end
            if addr == 0x0014 then addr = 0x0004 end
            if addr == 0x0018 then addr = 0x0008 end
            if addr == 0x001C then addr = 0x000C end
            return nameTable.tblPalette[addr]
        else
            print(string.format("PPU Error Read Memory %t", addr))
            return 0
        end
        return 0
    end
    
    function ppuBus.PPUWrite(addr, data)
    -- Mirrors 0x0 - 0x3FFF
        addr = bit.band(addr, 0x3FFF)
        local cartMapper = mapper[cart.mapper].mapper
    -- Pattern Tables CHR ROM
        if addr >= 0x0000 and addr <= 0x1FFF then
            cartMapper.PPUWrite(addr,data)
            return data
    -- Access internal NameTable Memory VRAM
        elseif addr >= 0x2000 and addr <= 0x3EFF then
                return nameTable.NameTableMirrorWrite(addr, data)
    -- Palette Memory Palette 
        elseif addr >= 0x3F00 and addr <= 0x3FFF then
            addr = bit.band(addr,0x001F)
            if addr == 0x0010 then addr = 0x0000 end
            if addr == 0x0014 then addr = 0x0004 end
            if addr == 0x0018 then addr = 0x0008 end
            if addr == 0x001C then addr = 0x000C end
            nameTable.tblPalette[addr] = data
            return
        else
            print(string.format("PPU Error Write Memory %x %x", addr, data))
        end
    end

-- Function Return Buffer 
    function ppuBus.ppuBuffer(startAddress, stopAddress)
        local Buffer = {}
        for i = startAddress,stopAddress do
            Buffer[i] = ppuBus.PPURead(i)
        end
        return Buffer
    end

    function ppuBus.ppuScanLineUpdate(scanLines)
        if cart.mapper == 4 then
            mapper[cart.mapper].mapper.ScanLineUpdate(scanLines)
        end
    end
return ppuBus
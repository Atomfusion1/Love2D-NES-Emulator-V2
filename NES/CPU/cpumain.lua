local opcodeTable   = require("NES.CPU.opcodes.opcodeTable")
local cpuInternal   = require("NES.CPU.cpuInternal")
local cart          = require("NES.Cartridge.Cartridge")
local ppu           = require("NES.PPU.ppu")
local ppuIO         = require("NES.PPU.ppuIO")
local bus           = require("NES.BUS.bus")
local addressMode   = require("NES.CPU.OpCodes.addressmodes")
local apu           = require("NES.Audio.apu")
local loopy         = require("NES.PPU.loopy")

-- # 6502 CPU
local cpu         = {}
local rshift, band, bor = bit.rshift, bit.band, bit.bor
local CPURead = bus.CPURead
local debugCPU = false

function cpu.Initialize(startPCAt)
    cpuInternal.A              = 0x00
    cpuInternal.X              = 0x00
    cpuInternal.Y              = 0x00
    cpuInternal.stackPointer   = 0xFD
    cpuInternal.statusRegister = 0x24
    cpuInternal.info.cycle     = 7
    cpuInternal.info.execute   = 0
    --memory.Initialize(0x00)
    print(CPURead(0xfffb))
    cpuInternal.NMIInterrupt   = CPURead(0xfffb) * 256 + CPURead(0xfffa)
    -- Change Startup for Debug nesTest
    if startPCAt then
        cpuInternal.programCounter = startPCAt
    else
        cpuInternal.resetInterrupt = CPURead(0xfffd) * 256 + CPURead(0xfffc)
        cpuInternal.programCounter = cpuInternal.resetInterrupt
        print(string.format("CPU ini %x",cpuInternal.programCounter))
    end
    cpuInternal.BRKInterrupt = CPURead(0xffff) * 256 + CPURead(0xfffe)

    cpuInternal.CHRLocation  = cart.header[0x04] * 0x4000 + 0x010 -- offset Header

    print(string.format("NMI:%x, PC:%x, BRK:%x, CHRLocation:%x CartMapper:%x", cpuInternal.NMIInterrupt, cpuInternal.programCounter,
        cpuInternal.BRKInterrupt, cpuInternal.CHRLocation, cart.mapper))
    print("CPU Initialized")

end

-- # Interrupt BRK
function DoBRK()
    -- Store Highbyte current Stack + 2
    addressMode.WriteToStack(rshift(cpuInternal.programCounter + 2, 8))
    -- Store Lowbyte current Stack + 2
    addressMode.WriteToStack(band(cpuInternal.programCounter + 2, 0xFF))
    -- Processor Status To Stack
    addressMode.WriteToStack(bor(cpuInternal.statusRegister, 0x30))
    -- jump to BRK vector 
    cpuInternal.programCounter = cpuInternal.BRKInterrupt
    return CPURead(cpuInternal.programCounter)
end

-- # Interrupt NMI
function cpu.DoNMI()
    --print("*NMI Trigger")
    cpuInternal.TriggerNMI = false
    -- Store Highbyte current Stack
    addressMode.WriteToStack(rshift(cpuInternal.programCounter, 8))
    -- Store Lowbyte current Stack
    addressMode.WriteToStack(band(cpuInternal.programCounter, 0xFF))
    -- Processor Status To Stack
    addressMode.WriteToStack(bor(cpuInternal.statusRegister, 0x30))
    -- jump to NMI vector
    cpuInternal.programCounter = CPURead(0xFFFB) * 256 + CPURead(0xFFFA)
end

-- # Interrupt IRQ
function cpu.DoIRQ()
    --print("*IRQ Trigger", ppu.scanLines)
    ppu.savePPUStates(ppu.scanLines)
    -- Check if the I (Interrupt disable) flag is set
    if band(cpuInternal.statusRegister, 0x04) == 0 then
        -- Store Highbyte current Stack
        addressMode.WriteToStack(rshift(cpuInternal.programCounter, 8))
        -- Store Lowbyte current Stack
        addressMode.WriteToStack(band(cpuInternal.programCounter, 0xFF))
        -- Processor Status To Stack
        addressMode.WriteToStack(bor(cpuInternal.statusRegister, 0x30))
        -- Jump to IRQ vector
        cpuInternal.programCounter = CPURead(0xFFFF) * 256 + CPURead(0xFFFE)
    end
end

-- ! This needs to be As Fast As Possible .. with just Flags it takes 9000 microSeconds to complete .. You have 16600 micros per frame
-- ? The PPU should probably be done on a second thread
function cpu.ExecuteCycles(totalCycles)
    local cycleCost, cycleCount, pcStep = 0, 0, 0
    local table = opcodeTable
    local checkppu = ppu.Update
    local CPURead = CPURead
    local results = 0x00

    while totalCycles > cycleCount do
        -- Reset PPU with CPU
        if ppu.scanLines == -1 then
            ppu.scanLines = 0
            ppu.scanLinePixels = 0
            -- reset trigger for NMI
            ppu.NMIArmed  = true
        end
        -- # Handle NMI
        if cpuInternal.TriggerNMI then
            cpu.DoNMI()
        end
        -- # Handle IRQ
        if bus.CheckIRQ() then
            cpu.DoIRQ()
        end
        --* Get current opcode to execute
        if UseBreakPoint and cpuInternal.programCounter == BreakPointValue then cycleCount = cpu.BreakPoint(BreakPointValue, totalCycles) end
        local opcode = CPURead(cpuInternal.programCounter)
        -- # Handle BRK
        if opcode == 0x00 then
            opcode = DoBRK()
        end
        --* Handle Opcode check for nils
        if opcode == nil then
            print("NIL OPCODE or 0x00!!!")
            print(string.format("Crash at opcode PCounter:%x Read:%x ",cpuInternal.programCounter, CPURead(cpuInternal.programCounter)))
            --opcode = 0xEA
        end
        local opTable = table[opcode]
        --* Handle Opcode check for nils
        if opTable == nil then
            print("opTable NIL !!! ")
            print(string.format("Crash at opTable PCounter:%x Read:%x Opcode %x",cpuInternal.programCounter, CPURead(cpuInternal.programCounter),opcode))
            --opTable = table[0xEA]
        end
        -- # Execute opcode
        if addressMode.debugPrint then 
            -- print(string.format("CPU Debug %x %x %x",cpuInternal.programCounter, CPURead(cpuInternal.programCounter),opcode )) 
            TraceLogger()
        end
        results, pcStep, cycleCost        = opTable.execute()
        cpuInternal.programCounter = band((cpuInternal.programCounter + pcStep), 0xFFFF)

        -- Update cycle count and debug information
        cycleCount               = cycleCount + cycleCost
        cpuInternal.info.execute   = cpuInternal.info.execute + 1
        cpuInternal.info.cycle     = cycleCost + cpuInternal.info.cycle

        -- # Update PPU
        checkppu(cycleCost)
    end
end

-- # Debugging
local file
local function TraceString()
    -- A:80 X:03 Y:03 S:EE P:NvubdIzc                  $C04D: EA        NOP
    local string = string.format("A:%x X:%x Y:%x S:%x P:%x              %x: %s: %x %x  \n",
        cpuInternal.A, cpuInternal.X, cpuInternal.Y, cpuInternal.stackPointer, cpuInternal.statusRegister,
        cpuInternal.programCounter, opcodeTable[CPURead(cpuInternal.programCounter)].mnemonic, 
        CPURead(cpuInternal.programCounter+1), CPURead(cpuInternal.programCounter+2))
    return string
end

--! This was a Quick Implimentation of the TraceLogger .. it needs to be reworked to be more efficient and less of a hack job
local recent_program_counters = {}
local max_pattern_size = 6
local skipped_lines = 0

--% TraceLogger Detect Patterns and Stop Printing them
local function detect_pattern(recentPC, maxSize)
    for pattern_length = 1, maxSize do
        local pattern_found = true
        for idx = 1, pattern_length do
            local base = recentPC[#recentPC - pattern_length + idx]
            local compare = recentPC[#recentPC - 2 * pattern_length + idx]
            if base ~= compare then
                pattern_found = false
                break
            end
        end
        if pattern_found then
            return true
        end
    end
    return false
end

--% Process and save Trace String
local function process_trace_string(trace_string, program_counter)
    table.insert(recent_program_counters, program_counter)
    if #recent_program_counters > 2 * max_pattern_size then
        table.remove(recent_program_counters, 1)
    end
    local pattern_found = detect_pattern(recent_program_counters, max_pattern_size)
    if pattern_found then
        skipped_lines = skipped_lines + 1
        return nil
    else
        local output_string = trace_string
        if skipped_lines > 0 then
            output_string = "(" .. skipped_lines .. " lines skipped)\n" .. trace_string
            skipped_lines = 0
        end
        return output_string
    end
end

--% TraceLogger Main Function
function TraceLogger()
    local trace_string = TraceString()
    local processed_string = process_trace_string(trace_string, cpuInternal.programCounter)
    if file then
        if processed_string then
            file:write(processed_string)
        else
            skipped_lines = skipped_lines + 1
        end
    else
        file = io.open(LoveFileDir.."Trace.log", "a")
        if file then 
            file:write("FCEUX 2.6.4 - Trace Log File")
        else
            print("Error: Unable to open the file.")
        end
    end
end

UseBreakPoint = false
BreakPointValue = 0x00
function cpu.BreakPoint(value, totalCycles)
    print("Breakpoint Hit Stopped At:"..value)
    step = 0
    return totalCycles
end

return cpu

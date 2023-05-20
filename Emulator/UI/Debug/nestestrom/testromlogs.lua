local bus = require("NES.BUS.bus")
local cpuMemory = require("NES.CPU.cpuInternal")
local opcodeTable = require("NES.CPU.opcodes.opcodeTable")
local ppu = require("NES.PPU.ppu")

Test = {
    Line            = 1,
    Address         = 0x00,
    OpcodeHex       = 0x00,
    NumOfCodes      = 0x00,
    Op1             = 0x00,
    Op2             = 0x00,
    OpCodeTxt       = "",
    Accumulator     = 0x00,
    X               = 0x00,
    Y               = 0x00,
    FlagHex         = 0x00,
    StackPointer    = 0x00,
    PPU             = 0x00,
    CPUCycle        = 0x07,
}

local holder = 0
function Test.PrintOutput(startAt)
  if not Test.LogArray.Loaded then Test.LoadLogFile() end
  Test.Line = Test.Line + 1 -- add 1 to line number
  Test.UpdateValues()
  if holder >= startAt then
    Test.TestStart(Test.Line,
        string.format(
            "%4x  %2x %2x %2x  %s $%2x                         A:%2x X:%2x Y:%2x P:%2x SP:%2x PPU:  %4i  CYC:%i",
            Test.Address, Test.OpcodeHex, Test.Op1, Test.Op2, Test.OpCodeTxt, Test.Op1, Test.Accumulator, Test.X, Test.Y,
            Test.FlagHex, bit.band(Test.StackPointer, 0xFF), 0, Test.CPUCycle))
  end
  holder = holder + 1
end

function Test.UpdateValues()
  Test.Address = cpuMemory.programCounter
  Test.OpcodeHex = bus.CPURead(Test.Address)
  Test.Op1 = bus.CPURead(Test.Address + 1)
  Test.Op2 = bus.CPURead(Test.Address + 2)
  if opcodeTable[Test.OpcodeHex] then
    opcode1 = opcodeTable[Test.OpcodeHex].opcode
  else
    opcode1 = "UNK"
  end
  Test.OpCodeTxt = opcode1
  Test.Accumulator = cpuMemory.A
  Test.X = cpuMemory.X
  Test.Y = cpuMemory.Y
  Test.FlagHex = cpuMemory.statusRegister
  Test.StackPointer = cpuMemory.stackPointer
  Test.CPUCycle = cpuMemory.info.cycle
end

function Test.TestStart(int, string1)
  local string = int .. " " .. string1
  string = string.upper(string)
  local string2 = int .. " " .. Test.LogArray[int]
  local stringreturn = Test.compareStrings(string, string2)
  print(string)
  print(string2)
  print(stringreturn)
end

function Test.compareStrings(string1, string2)
  local difference = ""
  for i = 1, math.max(#string1, #string2) do
    local char1 = string1:sub(i, i) or ""
    local char2 = string2:sub(i, i) or ""
    --if i == 24 then difference = difference.."X" end
    if char1 ~= char2 then
      if char1 == " " and char2 == '0' or char2 == '=' or char2 == ',' or char2 == '#'
          or char1 == ' ' and char2 == '$' or i > 80 and i < 90 or i > 24 and i < 35 then
        difference = difference .. " "
      else
        difference = difference .. char2
      end
    else
      difference = difference .. " "
    end
  end
  return difference
end

-- This file is for Loading and storing the Rom in Memory
-- relative file location
local filestring = love.filesystem.getSourceBaseDirectory() .. "\\" .. love.filesystem.getIdentity() .. "\\"
Test.LogArray = {}
function Test.LoadLogFile()
  local file = io.open(filestring .. "nestestrom/nestest.log", "r")
  if file then
    Test.LogArray.Loaded = true
    for line in file:lines() do
      Test.LogArray[#Test.LogArray + 1] = line
    end
    file:close()
  end
end

return Test

-- x = unsigned hexadecimal
-- s = string of characters
-- i = integers

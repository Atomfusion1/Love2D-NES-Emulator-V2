local addressMode = require("NES.CPU.opcodes.addressmodes")
--local functionMode = require("NES.CPU.opcodes.opcodefunctions")
local functionA_G = require("NES.CPU.opcodes.functionsA_G")
local functionH_N = require("NES.CPU.opcodes.functionsH_N")
local functionO_T = require("NES.CPU.opcodes.functionsO_T")
local functionU_Z = require("NES.CPU.opcodes.functionsU_Z")
local illegalOpcode = require("NES.CPU.opcodes.illegalOpcodes")
-- Define the opcode table
local opcodeTable = {}

function opcodeTable.AddOpcode(opcode, mnemonic, getAddressMode, action, bytes, cycles)
    opcodeTable[opcode] = {
        mnemonic = mnemonic,
        getAddressMode = getAddressMode,
        action = action,
        bytes = bytes,
        cycles = cycles,
        execute = function(cpu)
            local value, addressType, c2 = getAddressMode(cpu)
            local result, b1, c1 = action(value, addressType)
            return result, bytes + b1, cycles + c1 + c2
        end
    }
end
--ADC
opcodeTable.AddOpcode(0x69, "ADC", addressMode.GetImmediateMode, functionA_G.ADCFunction, 2, 2)
opcodeTable.AddOpcode(0x6D, "ADC", addressMode.GetAbsoluteAddressMode, functionA_G.ADCFunction, 3, 4)
opcodeTable.AddOpcode(0x7D, "ADC", addressMode.GetAbsolute_XAddressMode, functionA_G.ADCFunction, 3, 4)
opcodeTable.AddOpcode(0x79, "ADC", addressMode.GetAbsolute_YAddressMode, functionA_G.ADCFunction, 3, 4)
opcodeTable.AddOpcode(0x65, "ADC", addressMode.GetZeroPageAddressMode, functionA_G.ADCFunction, 2, 3)
opcodeTable.AddOpcode(0x75, "ADC", addressMode.GetZeroPage_XAddressMode, functionA_G.ADCFunction, 2, 4)
opcodeTable.AddOpcode(0x61, "ADC", addressMode.GetIndexed_Indirect_XMode, functionA_G.ADCFunction, 2, 6)
opcodeTable.AddOpcode(0x71, "ADC", addressMode.GetIndirect_Indexed_YMode, functionA_G.ADCFunction, 2, 5)
--SBC
opcodeTable.AddOpcode(0xE9, "SBC", addressMode.GetImmediateMode, functionO_T.SBCFunction, 2, 2)
opcodeTable.AddOpcode(0xED, "SBC", addressMode.GetAbsoluteAddressMode, functionO_T.SBCFunction, 3, 4)
opcodeTable.AddOpcode(0xFD, "SBC", addressMode.GetAbsolute_XAddressMode, functionO_T.SBCFunction, 3, 4)
opcodeTable.AddOpcode(0xF9, "SBC", addressMode.GetAbsolute_YAddressMode, functionO_T.SBCFunction, 3, 4)
opcodeTable.AddOpcode(0xE5, "SBC", addressMode.GetZeroPageAddressMode, functionO_T.SBCFunction, 2, 3)
opcodeTable.AddOpcode(0xF5, "SBC", addressMode.GetZeroPage_XAddressMode, functionO_T.SBCFunction, 2, 4)
opcodeTable.AddOpcode(0xE1, "SBC", addressMode.GetIndexed_Indirect_XMode, functionO_T.SBCFunction, 2, 6)
opcodeTable.AddOpcode(0xF1, "SBC", addressMode.GetIndirect_Indexed_YMode, functionO_T.SBCFunction, 2, 5)
--LDX
opcodeTable.AddOpcode(0xA2, "LDX", addressMode.GetImmediateMode, functionH_N.LDXFunction, 2, 2)
opcodeTable.AddOpcode(0xAE, "LDX", addressMode.GetAbsoluteAddressMode, functionH_N.LDXFunction, 3, 4)
opcodeTable.AddOpcode(0xBE, "LDX", addressMode.GetAbsolute_YAddressMode, functionH_N.LDXFunction, 3, 4)
opcodeTable.AddOpcode(0xA6, "LDX", addressMode.GetZeroPageAddressMode, functionH_N.LDXFunction, 2, 3)
opcodeTable.AddOpcode(0xB6, "LDX", addressMode.GetZeroPage_YAddressMode, functionH_N.LDXFunction, 2, 4)
-- Branches
opcodeTable.AddOpcode(0x10, "BPL", addressMode.Relative, functionA_G.BPLFunction, 2, 2)
opcodeTable.AddOpcode(0xB0, "BCS", addressMode.Relative, functionA_G.BCSFunction, 2, 2)
opcodeTable.AddOpcode(0x90, "BCC", addressMode.Relative, functionA_G.BCCFunction, 2, 2)
opcodeTable.AddOpcode(0xF0, "BEQ", addressMode.Relative, functionA_G.BEQFunction, 2, 2)
opcodeTable.AddOpcode(0x30, "BMI", addressMode.Relative, functionA_G.BMIFunction, 2, 2)
opcodeTable.AddOpcode(0xD0, "BNE", addressMode.Relative, functionA_G.BNEFunction, 2, 2)
opcodeTable.AddOpcode(0x50, "BVC", addressMode.Relative, functionA_G.BVCFunction, 2, 2)
opcodeTable.AddOpcode(0x70, "BVS", addressMode.Relative, functionA_G.BVSFunction, 2, 2)
-- JUMPS
opcodeTable.AddOpcode(0x4C, "JMP", addressMode.GetAbsoluteAddressMode, functionH_N.JMPFunction, 1, 3) -- 0 as you set pointerCounter
opcodeTable.AddOpcode(0x6C, "JMP", addressMode.GetAbsoluteIndirectMode, functionH_N.JMPFunction, 1, 5) -- 0 as you set pointerCounter
opcodeTable.AddOpcode(0x20, "JSR", addressMode.GetAbsoluteAddressMode, functionH_N.JSRFunction, 1, 6) -- 0 as you set pointerCounter
opcodeTable.AddOpcode(0x60, "RTS", addressMode.Implied, functionO_T.RTSFunction, 0, 6)
--Flags 
opcodeTable.AddOpcode(0x18, "CLC", addressMode.Implied, functionA_G.CLCFunction, 1, 2)
opcodeTable.AddOpcode(0xD8, "CLD", addressMode.Implied, functionA_G.CLDFunction, 1, 2)
opcodeTable.AddOpcode(0x58, "CLI", addressMode.Implied, functionA_G.CLIFunction, 1, 2)
opcodeTable.AddOpcode(0xB8, "CLV", addressMode.Implied, functionA_G.CLVFunction, 1, 2)
opcodeTable.AddOpcode(0x38, "SEC", addressMode.Implied, functionO_T.SECFunction, 1, 2)
opcodeTable.AddOpcode(0xF8, "SED", addressMode.Implied, functionO_T.SEDFunction, 1, 2)
opcodeTable.AddOpcode(0x78, "SEI", addressMode.Implied, functionO_T.SEIFunction, 1, 2)
--NOP
opcodeTable.AddOpcode(0xEA, "NOP", addressMode.Implied, functionH_N.NOPFunction, 1, 2)
opcodeTable.AddOpcode(0x00, "NOP", addressMode.Implied, functionH_N.NOPFunction, 1, 2)
--LDA
opcodeTable.AddOpcode(0xA9, "LDA", addressMode.GetImmediateMode, functionH_N.LDAFunction, 2, 2)
opcodeTable.AddOpcode(0xAD, "LDA", addressMode.GetAbsoluteAddressMode, functionH_N.LDAFunction, 3, 4)
opcodeTable.AddOpcode(0xBD, "LDA", addressMode.GetAbsolute_XAddressMode, functionH_N.LDAFunction, 3, 4)
opcodeTable.AddOpcode(0xB9, "LDA", addressMode.GetAbsolute_YAddressMode, functionH_N.LDAFunction, 3, 4)
opcodeTable.AddOpcode(0xA5, "LDA", addressMode.GetZeroPageAddressMode, functionH_N.LDAFunction, 2, 3)
opcodeTable.AddOpcode(0xB5, "LDA", addressMode.GetZeroPage_XAddressMode, functionH_N.LDAFunction, 2, 4)
opcodeTable.AddOpcode(0xA1, "LDA", addressMode.GetIndexed_Indirect_XMode, functionH_N.LDAFunction, 2, 6)
opcodeTable.AddOpcode(0xB1, "LDA", addressMode.GetIndirect_Indexed_YMode, functionH_N.LDAFunction, 2, 5)
--STA
opcodeTable.AddOpcode(0x8D, "STA", addressMode.GetAbsoluteAddressMode, functionO_T.STAFunction, 3, 4)
opcodeTable.AddOpcode(0x9D, "STA", addressMode.GetAbsolute_XAddressMode, functionO_T.STAFunction, 3, 5)
opcodeTable.AddOpcode(0x99, "STA", addressMode.GetAbsolute_YAddressMode, functionO_T.STAFunction, 3, 5)
opcodeTable.AddOpcode(0x85, "STA", addressMode.GetZeroPageAddressMode, functionO_T.STAFunction, 2, 3)
opcodeTable.AddOpcode(0x95, "STA", addressMode.GetZeroPage_XAddressMode, functionO_T.STAFunction, 2, 4)
opcodeTable.AddOpcode(0x81, "STA", addressMode.GetIndexed_Indirect_XMode, functionO_T.STAFunction, 2, 6)
opcodeTable.AddOpcode(0x91, "STA", addressMode.GetIndirect_Indexed_YMode, functionO_T.STAFunction, 2, 6)
--STX
opcodeTable.AddOpcode(0x8E, "STX", addressMode.GetAbsoluteAddressMode, functionO_T.STXFunction, 3, 4)
opcodeTable.AddOpcode(0x86, "STX", addressMode.GetZeroPageAddressMode, functionO_T.STXFunction, 2, 3)
opcodeTable.AddOpcode(0x96, "STX", addressMode.GetZeroPage_YAddressMode, functionO_T.STXFunction, 2, 4)
--STY
opcodeTable.AddOpcode(0x8C, "STY", addressMode.GetAbsoluteAddressMode, functionO_T.STYFunction, 3, 4)
opcodeTable.AddOpcode(0x84, "STY", addressMode.GetZeroPageAddressMode, functionO_T.STYFunction, 2, 3)
opcodeTable.AddOpcode(0x94, "STY", addressMode.GetZeroPage_XAddressMode, functionO_T.STYFunction, 2, 4)
--BIT
opcodeTable.AddOpcode(0x2C, "BIT", addressMode.GetAbsoluteAddressMode, functionA_G.BITFunction, 3, 4)
opcodeTable.AddOpcode(0x24, "BIT", addressMode.GetZeroPageAddressMode, functionA_G.BITFunction, 2, 3)
--STACK
opcodeTable.AddOpcode(0x48, "PHA", addressMode.Implied, functionO_T.PHAFunction, 1, 3)
opcodeTable.AddOpcode(0x08, "PHP", addressMode.Implied, functionO_T.PHPFunction, 1, 3)
opcodeTable.AddOpcode(0x68, "PLA", addressMode.Implied, functionO_T.PLAFunction, 1, 4)
opcodeTable.AddOpcode(0x28, "PLP", addressMode.Implied, functionO_T.PLPFunction, 1, 4)
--AND
opcodeTable.AddOpcode(0x29, "AND", addressMode.GetImmediateMode, functionA_G.ANDFunction, 2, 2)
opcodeTable.AddOpcode(0x2D, "AND", addressMode.GetAbsoluteAddressMode, functionA_G.ANDFunction, 3, 4)
opcodeTable.AddOpcode(0x3D, "AND", addressMode.GetAbsolute_XAddressMode, functionA_G.ANDFunction, 3, 4)
opcodeTable.AddOpcode(0x39, "AND", addressMode.GetAbsolute_YAddressMode, functionA_G.ANDFunction, 3, 4)
opcodeTable.AddOpcode(0x25, "AND", addressMode.GetZeroPageAddressMode, functionA_G.ANDFunction, 2, 3)
opcodeTable.AddOpcode(0x35, "AND", addressMode.GetZeroPage_XAddressMode, functionA_G.ANDFunction, 2, 4)
opcodeTable.AddOpcode(0x21, "AND", addressMode.GetIndexed_Indirect_XMode, functionA_G.ANDFunction, 2, 6)
opcodeTable.AddOpcode(0x31, "AND", addressMode.GetIndirect_Indexed_YMode, functionA_G.ANDFunction, 2, 5)
--CMP
opcodeTable.AddOpcode(0xC9, "CMP", addressMode.GetImmediateMode, functionA_G.CMPFunction, 2, 2)
opcodeTable.AddOpcode(0xCD, "CMP", addressMode.GetAbsoluteAddressMode, functionA_G.CMPFunction, 3, 4)
opcodeTable.AddOpcode(0xDD, "CMP", addressMode.GetAbsolute_XAddressMode, functionA_G.CMPFunction, 3, 4)
opcodeTable.AddOpcode(0xD9, "CMP", addressMode.GetAbsolute_YAddressMode, functionA_G.CMPFunction, 3, 4)
opcodeTable.AddOpcode(0xC5, "CMP", addressMode.GetZeroPageAddressMode, functionA_G.CMPFunction, 2, 3)
opcodeTable.AddOpcode(0xD5, "CMP", addressMode.GetZeroPage_XAddressMode, functionA_G.CMPFunction, 2, 4)
opcodeTable.AddOpcode(0xC1, "CMP", addressMode.GetIndexed_Indirect_XMode, functionA_G.CMPFunction, 2, 6)
opcodeTable.AddOpcode(0xD1, "CMP", addressMode.GetIndirect_Indexed_YMode, functionA_G.CMPFunction, 2, 5)
--ORA
opcodeTable.AddOpcode(0x09, "ORA", addressMode.GetImmediateMode, functionO_T.ORAFunction, 2, 2)
opcodeTable.AddOpcode(0x0D, "ORA", addressMode.GetAbsoluteAddressMode, functionO_T.ORAFunction, 3, 4)
opcodeTable.AddOpcode(0x1D, "ORA", addressMode.GetAbsolute_XAddressMode, functionO_T.ORAFunction, 3, 4)
opcodeTable.AddOpcode(0x19, "ORA", addressMode.GetAbsolute_YAddressMode, functionO_T.ORAFunction, 3, 4)
opcodeTable.AddOpcode(0x05, "ORA", addressMode.GetZeroPageAddressMode, functionO_T.ORAFunction, 2, 3)
opcodeTable.AddOpcode(0x15, "ORA", addressMode.GetZeroPage_XAddressMode, functionO_T.ORAFunction, 2, 4)
opcodeTable.AddOpcode(0x01, "ORA", addressMode.GetIndexed_Indirect_XMode, functionO_T.ORAFunction, 2, 6)
opcodeTable.AddOpcode(0x11, "ORA", addressMode.GetIndirect_Indexed_YMode, functionO_T.ORAFunction, 2, 5)
--EOR
opcodeTable.AddOpcode(0x49, "EOR", addressMode.GetImmediateMode, functionA_G.EORFunction, 2, 2)
opcodeTable.AddOpcode(0x4D, "EOR", addressMode.GetAbsoluteAddressMode, functionA_G.EORFunction, 3, 4)
opcodeTable.AddOpcode(0x5D, "EOR", addressMode.GetAbsolute_XAddressMode, functionA_G.EORFunction, 3, 4)
opcodeTable.AddOpcode(0x59, "EOR", addressMode.GetAbsolute_YAddressMode, functionA_G.EORFunction, 3, 4)
opcodeTable.AddOpcode(0x45, "EOR", addressMode.GetZeroPageAddressMode, functionA_G.EORFunction, 2, 3)
opcodeTable.AddOpcode(0x55, "EOR", addressMode.GetZeroPage_XAddressMode, functionA_G.EORFunction, 2, 4)
opcodeTable.AddOpcode(0x41, "EOR", addressMode.GetIndexed_Indirect_XMode, functionA_G.EORFunction, 2, 6)
opcodeTable.AddOpcode(0x51, "EOR", addressMode.GetIndirect_Indexed_YMode, functionA_G.EORFunction, 2, 5)
--LDY
opcodeTable.AddOpcode(0xA0, "LDY", addressMode.GetImmediateMode, functionH_N.LDYFunction, 2, 2)
opcodeTable.AddOpcode(0xAC, "LDY", addressMode.GetAbsoluteAddressMode, functionH_N.LDYFunction, 3, 4)
opcodeTable.AddOpcode(0xBC, "LDY", addressMode.GetAbsolute_XAddressMode, functionH_N.LDYFunction, 3, 4)
opcodeTable.AddOpcode(0xA4, "LDY", addressMode.GetZeroPageAddressMode, functionH_N.LDYFunction, 2, 3)
opcodeTable.AddOpcode(0xB4, "LDY", addressMode.GetZeroPage_XAddressMode, functionH_N.LDYFunction, 2, 4)
--CPY
opcodeTable.AddOpcode(0xC0, "CPY", addressMode.GetImmediateMode, functionA_G.CPYFunction, 2, 2)
opcodeTable.AddOpcode(0xCC, "CPY", addressMode.GetAbsoluteAddressMode, functionA_G.CPYFunction, 3, 4)
opcodeTable.AddOpcode(0xC4, "CPY", addressMode.GetZeroPageAddressMode, functionA_G.CPYFunction, 2, 3)
--CPX
opcodeTable.AddOpcode(0xE0, "CPX", addressMode.GetImmediateMode, functionA_G.CPXFunction, 2, 2)
opcodeTable.AddOpcode(0xEC, "CPX", addressMode.GetAbsoluteAddressMode, functionA_G.CPXFunction, 3, 4)
opcodeTable.AddOpcode(0xE4, "CPX", addressMode.GetZeroPageAddressMode, functionA_G.CPXFunction, 2, 3)
--INY
opcodeTable.AddOpcode(0xC8, "INY", addressMode.Implied, functionH_N.INYFunction, 1, 2)
--INX
opcodeTable.AddOpcode(0xE8, "INX", addressMode.Implied, functionH_N.INXFunction, 1, 2)
--INC
opcodeTable.AddOpcode(0xEE, "INC", addressMode.GetAbsoluteAddressMode, functionH_N.INCFunction, 3, 6)
opcodeTable.AddOpcode(0xFE, "INC", addressMode.GetAbsolute_XAddressMode, functionH_N.INCFunction, 3, 7)
opcodeTable.AddOpcode(0xE6, "INC", addressMode.GetZeroPageAddressMode, functionH_N.INCFunction, 2, 5)
opcodeTable.AddOpcode(0xF6, "INC", addressMode.GetZeroPage_XAddressMode, functionH_N.INCFunction, 2, 6)
--DEY
opcodeTable.AddOpcode(0x88, "DEY", addressMode.Implied, functionA_G.DEYFunction, 1, 2)
--DEX
opcodeTable.AddOpcode(0xCA, "DEX", addressMode.Implied, functionA_G.DEXFunction, 1, 2)
--DEC
opcodeTable.AddOpcode(0xCE, "DEC", addressMode.GetAbsoluteAddressMode, functionA_G.DECFunction, 3, 6)
opcodeTable.AddOpcode(0xDE, "DEC", addressMode.GetAbsolute_XAddressMode, functionA_G.DECFunction, 3, 7)
opcodeTable.AddOpcode(0xC6, "DEC", addressMode.GetZeroPageAddressMode, functionA_G.DECFunction, 2, 5)
opcodeTable.AddOpcode(0xD6, "DEC", addressMode.GetZeroPage_XAddressMode, functionA_G.DECFunction, 2, 6)
--Transfers
opcodeTable.AddOpcode(0xAA, "TAX", addressMode.Implied, functionO_T.TAXFunction, 1, 2)
opcodeTable.AddOpcode(0xA8, "TAY", addressMode.Implied, functionO_T.TAYFunction, 1, 2)
opcodeTable.AddOpcode(0xBA, "TSX", addressMode.Implied, functionO_T.TSXFunction, 1, 2)
opcodeTable.AddOpcode(0x8A, "TXA", addressMode.Implied, functionO_T.TXAFunction, 1, 2)
opcodeTable.AddOpcode(0x9A, "TXS", addressMode.Implied, functionO_T.TXSFunction, 1, 2)
opcodeTable.AddOpcode(0x98, "TYA", addressMode.Implied, functionO_T.TYAFunction, 1, 2)
--RTI
opcodeTable.AddOpcode(0x40, "RTI", addressMode.Implied, functionO_T.RTIFunction, 1, 6)
--LSR
opcodeTable.AddOpcode(0x4A, "LSR", addressMode.Accumulator, functionH_N.LSRFunction, 1, 2)
opcodeTable.AddOpcode(0x4E, "LSR", addressMode.GetAbsoluteAddressMode, functionH_N.LSRFunction, 3, 6)
opcodeTable.AddOpcode(0x5E, "LSR", addressMode.GetAbsolute_XAddressMode, functionH_N.LSRFunction, 3, 7)
opcodeTable.AddOpcode(0x46, "LSR", addressMode.GetZeroPageAddressMode, functionH_N.LSRFunction, 2, 5)
opcodeTable.AddOpcode(0x56, "LSR", addressMode.GetZeroPage_XAddressMode, functionH_N.LSRFunction, 2, 6)
--ASL
opcodeTable.AddOpcode(0x0A, "ASL", addressMode.Accumulator, functionA_G.ASLFunction, 1, 2)
opcodeTable.AddOpcode(0x0E, "ASL", addressMode.GetAbsoluteAddressMode, functionA_G.ASLFunction, 3, 6)
opcodeTable.AddOpcode(0x1E, "ASL", addressMode.GetAbsolute_XAddressMode, functionA_G.ASLFunction, 3, 7)
opcodeTable.AddOpcode(0x06, "ASL", addressMode.GetZeroPageAddressMode, functionA_G.ASLFunction, 2, 5)
opcodeTable.AddOpcode(0x16, "ASL", addressMode.GetZeroPage_XAddressMode, functionA_G.ASLFunction, 2, 6)
--ROR
opcodeTable.AddOpcode(0x6A, "ROR", addressMode.Accumulator, functionO_T.RORFunction, 1, 2)
opcodeTable.AddOpcode(0x6E, "ROR", addressMode.GetAbsoluteAddressMode, functionO_T.RORFunction, 3, 6)
opcodeTable.AddOpcode(0x7E, "ROR", addressMode.GetAbsolute_XAddressMode, functionO_T.RORFunction, 3, 7)
opcodeTable.AddOpcode(0x66, "ROR", addressMode.GetZeroPageAddressMode, functionO_T.RORFunction, 2, 5)
opcodeTable.AddOpcode(0x76, "ROR", addressMode.GetZeroPage_XAddressMode, functionO_T.RORFunction, 2, 6)
--ROL
opcodeTable.AddOpcode(0x2A, "ROL", addressMode.Accumulator, functionO_T.ROLFunction, 1, 2)
opcodeTable.AddOpcode(0x2E, "ROL", addressMode.GetAbsoluteAddressMode, functionO_T.ROLFunction, 3, 6)
opcodeTable.AddOpcode(0x3E, "ROL", addressMode.GetAbsolute_XAddressMode, functionO_T.ROLFunction, 3, 7)
opcodeTable.AddOpcode(0x26, "ROL", addressMode.GetZeroPageAddressMode, functionO_T.ROLFunction, 2, 5)
opcodeTable.AddOpcode(0x36, "ROL", addressMode.GetZeroPage_XAddressMode, functionO_T.ROLFunction, 2, 6)

-- ! ILLEGALOPCODES
-- NOP
opcodeTable.AddOpcode(0x1A, "NOP", addressMode.Implied, illegalOpcode.NOPFunction, 1, 2)
opcodeTable.AddOpcode(0x3A, "NOP", addressMode.Implied, illegalOpcode.NOPFunction, 1, 2)
opcodeTable.AddOpcode(0x5A, "NOP", addressMode.Implied, illegalOpcode.NOPFunction, 1, 2)
opcodeTable.AddOpcode(0x7A, "NOP", addressMode.Implied, illegalOpcode.NOPFunction, 1, 2)
opcodeTable.AddOpcode(0xDA, "NOP", addressMode.Implied, illegalOpcode.NOPFunction, 1, 2)
opcodeTable.AddOpcode(0xFA, "NOP", addressMode.Implied, illegalOpcode.NOPFunction, 1, 2)
opcodeTable.AddOpcode(0x80, "NOP", addressMode.GetImmediateMode, illegalOpcode.NOPFunction, 2, 2)
opcodeTable.AddOpcode(0x82, "NOP", addressMode.GetImmediateMode, illegalOpcode.NOPFunction, 2, 2)
opcodeTable.AddOpcode(0x89, "NOP", addressMode.GetImmediateMode, illegalOpcode.NOPFunction, 2, 2)
opcodeTable.AddOpcode(0xC2, "NOP", addressMode.GetImmediateMode, illegalOpcode.NOPFunction, 2, 2)
opcodeTable.AddOpcode(0xE2, "NOP", addressMode.GetImmediateMode, illegalOpcode.NOPFunction, 2, 2)
opcodeTable.AddOpcode(0x04, "NOP", addressMode.GetZeroPageAddressMode, illegalOpcode.NOPFunction, 2, 3)
opcodeTable.AddOpcode(0x44, "NOP", addressMode.GetZeroPageAddressMode, illegalOpcode.NOPFunction, 2, 3)
opcodeTable.AddOpcode(0x64, "NOP", addressMode.GetZeroPageAddressMode, illegalOpcode.NOPFunction, 2, 3)
opcodeTable.AddOpcode(0x14, "NOP", addressMode.GetZeroPage_XAddressMode, illegalOpcode.NOPFunction, 2, 4)
opcodeTable.AddOpcode(0x34, "NOP", addressMode.GetZeroPage_XAddressMode, illegalOpcode.NOPFunction, 2, 4)
opcodeTable.AddOpcode(0x54, "NOP", addressMode.GetZeroPage_XAddressMode, illegalOpcode.NOPFunction, 2, 4)
opcodeTable.AddOpcode(0x74, "NOP", addressMode.GetZeroPage_XAddressMode, illegalOpcode.NOPFunction, 2, 4)
opcodeTable.AddOpcode(0xD4, "NOP", addressMode.GetZeroPage_XAddressMode, illegalOpcode.NOPFunction, 2, 4)
opcodeTable.AddOpcode(0xF4, "NOP", addressMode.GetZeroPage_XAddressMode, illegalOpcode.NOPFunction, 2, 4)
opcodeTable.AddOpcode(0x0C, "NOP", addressMode.GetAbsoluteAddressMode, illegalOpcode.NOPFunction, 3, 4)
opcodeTable.AddOpcode(0x1C, "NOP", addressMode.GetAbsolute_XAddressMode, illegalOpcode.NOPFunction, 3, 4)
opcodeTable.AddOpcode(0x3C, "NOP", addressMode.GetAbsolute_XAddressMode, illegalOpcode.NOPFunction, 3, 4)
opcodeTable.AddOpcode(0x5C, "NOP", addressMode.GetAbsolute_XAddressMode, illegalOpcode.NOPFunction, 3, 4)
opcodeTable.AddOpcode(0x7C, "NOP", addressMode.GetAbsolute_XAddressMode, illegalOpcode.NOPFunction, 3, 4)
opcodeTable.AddOpcode(0xDC, "NOP", addressMode.GetAbsolute_XAddressMode, illegalOpcode.NOPFunction, 3, 4)
opcodeTable.AddOpcode(0xFC, "NOP", addressMode.GetAbsolute_XAddressMode, illegalOpcode.NOPFunction, 3, 4)
-- LAX
opcodeTable.AddOpcode(0xA7, "LAX", addressMode.GetZeroPageAddressMode, illegalOpcode.LAXFunction, 2, 3)
opcodeTable.AddOpcode(0xB7, "LAX", addressMode.GetZeroPage_YAddressMode, illegalOpcode.LAXFunction, 2, 4)
opcodeTable.AddOpcode(0xAF, "LAX", addressMode.GetAbsoluteAddressMode, illegalOpcode.LAXFunction, 3, 4)
opcodeTable.AddOpcode(0xBF, "LAX", addressMode.GetAbsolute_YAddressMode, illegalOpcode.LAXFunction, 3, 4)
opcodeTable.AddOpcode(0xA3, "LAX", addressMode.GetIndexed_Indirect_XMode, illegalOpcode.LAXFunction, 2, 6)
opcodeTable.AddOpcode(0xB3, "LAX", addressMode.GetIndirect_Indexed_YMode, illegalOpcode.LAXFunction, 2, 5)
-- SAX
opcodeTable.AddOpcode(0x87, "SAX", addressMode.GetZeroPageAddressMode, illegalOpcode.SAXFunction, 2, 3)
opcodeTable.AddOpcode(0x97, "SAX", addressMode.GetZeroPage_YAddressMode, illegalOpcode.SAXFunction, 2, 4)
opcodeTable.AddOpcode(0x8F, "SAX", addressMode.GetAbsoluteAddressMode, illegalOpcode.SAXFunction, 3, 4)
opcodeTable.AddOpcode(0x83, "SAX", addressMode.GetIndexed_Indirect_XMode, illegalOpcode.SAXFunction, 2, 6)
-- SBC
opcodeTable.AddOpcode(0xEB, "SBC", addressMode.GetImmediateMode, functionO_T.SBCFunction, 2, 2)
-- DCP
opcodeTable.AddOpcode(0xC7, "DCP", addressMode.GetZeroPageAddressMode, illegalOpcode.DCPFunction, 2, 5)
opcodeTable.AddOpcode(0xD7, "DCP", addressMode.GetZeroPage_XAddressMode, illegalOpcode.DCPFunction, 2, 6)
opcodeTable.AddOpcode(0xCF, "DCP", addressMode.GetAbsoluteAddressMode, illegalOpcode.DCPFunction, 3, 6)
opcodeTable.AddOpcode(0xDF, "DCP", addressMode.GetAbsolute_XAddressMode, illegalOpcode.DCPFunction, 3, 7)
opcodeTable.AddOpcode(0xDB, "DCP", addressMode.GetAbsolute_YAddressMode, illegalOpcode.DCPFunction, 3, 7)
opcodeTable.AddOpcode(0xC3, "DCP", addressMode.GetIndexed_Indirect_XMode, illegalOpcode.DCPFunction, 2, 8)
opcodeTable.AddOpcode(0xD3, "DCP", addressMode.GetIndirect_Indexed_YMode, illegalOpcode.DCPFunction, 2, 8)
-- ISC
opcodeTable.AddOpcode(0xE7, "ISC", addressMode.GetZeroPageAddressMode, illegalOpcode.ISCFunction, 2, 5)
opcodeTable.AddOpcode(0xF7, "ISC", addressMode.GetZeroPage_XAddressMode, illegalOpcode.ISCFunction, 2, 6)
opcodeTable.AddOpcode(0xEF, "ISC", addressMode.GetAbsoluteAddressMode, illegalOpcode.ISCFunction, 3, 6)
opcodeTable.AddOpcode(0xFF, "ISC", addressMode.GetAbsolute_XAddressMode, illegalOpcode.ISCFunction, 3, 7)
opcodeTable.AddOpcode(0xFB, "ISC", addressMode.GetAbsolute_YAddressMode, illegalOpcode.ISCFunction, 3, 7)
opcodeTable.AddOpcode(0xE3, "ISC", addressMode.GetIndexed_Indirect_XMode, illegalOpcode.ISCFunction, 2, 8)
opcodeTable.AddOpcode(0xF3, "ISC", addressMode.GetIndirect_Indexed_YMode, illegalOpcode.ISCFunction, 2, 8)
-- SLO
opcodeTable.AddOpcode(0x07, "SLO", addressMode.GetZeroPageAddressMode, illegalOpcode.SLOFunction, 2, 5)
opcodeTable.AddOpcode(0x17, "SLO", addressMode.GetZeroPage_XAddressMode, illegalOpcode.SLOFunction, 2, 6)
opcodeTable.AddOpcode(0x0F, "SLO", addressMode.GetAbsoluteAddressMode, illegalOpcode.SLOFunction, 3, 6)
opcodeTable.AddOpcode(0x1F, "SLO", addressMode.GetAbsolute_XAddressMode, illegalOpcode.SLOFunction, 3, 7)
opcodeTable.AddOpcode(0x1B, "SLO", addressMode.GetAbsolute_YAddressMode, illegalOpcode.SLOFunction, 3, 7)
opcodeTable.AddOpcode(0x03, "SLO", addressMode.GetIndexed_Indirect_XMode, illegalOpcode.SLOFunction, 2, 8)
opcodeTable.AddOpcode(0x13, "SLO", addressMode.GetIndirect_Indexed_YMode, illegalOpcode.SLOFunction, 2, 8)
-- RLA
opcodeTable.AddOpcode(0x27, "RLA", addressMode.GetZeroPageAddressMode, illegalOpcode.RLAFunction, 2, 5)
opcodeTable.AddOpcode(0x37, "RLA", addressMode.GetZeroPage_XAddressMode, illegalOpcode.RLAFunction, 2, 6)
opcodeTable.AddOpcode(0x2F, "RLA", addressMode.GetAbsoluteAddressMode, illegalOpcode.RLAFunction, 3, 6)
opcodeTable.AddOpcode(0x3F, "RLA", addressMode.GetAbsolute_XAddressMode, illegalOpcode.RLAFunction, 3, 7)
opcodeTable.AddOpcode(0x3B, "RLA", addressMode.GetAbsolute_YAddressMode, illegalOpcode.RLAFunction, 3, 7)
opcodeTable.AddOpcode(0x23, "RLA", addressMode.GetIndexed_Indirect_XMode, illegalOpcode.RLAFunction, 2, 8)
opcodeTable.AddOpcode(0x33, "RLA", addressMode.GetIndirect_Indexed_YMode, illegalOpcode.RLAFunction, 2, 8)
-- SRE
opcodeTable.AddOpcode(0x47, "SRE", addressMode.GetZeroPageAddressMode, illegalOpcode.SREFunction, 2, 5)
opcodeTable.AddOpcode(0x57, "SRE", addressMode.GetZeroPage_XAddressMode, illegalOpcode.SREFunction, 2, 6)
opcodeTable.AddOpcode(0x4F, "SRE", addressMode.GetAbsoluteAddressMode, illegalOpcode.SREFunction, 3, 6)
opcodeTable.AddOpcode(0x5F, "SRE", addressMode.GetAbsolute_XAddressMode, illegalOpcode.SREFunction, 3, 7)
opcodeTable.AddOpcode(0x5B, "SRE", addressMode.GetAbsolute_YAddressMode, illegalOpcode.SREFunction, 3, 7)
opcodeTable.AddOpcode(0x43, "SRE", addressMode.GetIndexed_Indirect_XMode, illegalOpcode.SREFunction, 2, 8)
opcodeTable.AddOpcode(0x53, "SRE", addressMode.GetIndirect_Indexed_YMode, illegalOpcode.SREFunction, 2, 8)
-- RRA
opcodeTable.AddOpcode(0x67, "RRA", addressMode.GetZeroPageAddressMode, illegalOpcode.RRAFunction, 2, 5)
opcodeTable.AddOpcode(0x77, "RRA", addressMode.GetZeroPage_XAddressMode, illegalOpcode.RRAFunction, 2, 6)
opcodeTable.AddOpcode(0x6F, "RRA", addressMode.GetAbsoluteAddressMode, illegalOpcode.RRAFunction, 3, 6)
opcodeTable.AddOpcode(0x7F, "RRA", addressMode.GetAbsolute_XAddressMode, illegalOpcode.RRAFunction, 3, 7)
opcodeTable.AddOpcode(0x7B, "RRA", addressMode.GetAbsolute_YAddressMode, illegalOpcode.RRAFunction, 3, 7)
opcodeTable.AddOpcode(0x63, "RRA", addressMode.GetIndexed_Indirect_XMode, illegalOpcode.RRAFunction, 2, 8)
opcodeTable.AddOpcode(0x73, "RRA", addressMode.GetIndirect_Indexed_YMode, illegalOpcode.RRAFunction, 2, 8)

return opcodeTable
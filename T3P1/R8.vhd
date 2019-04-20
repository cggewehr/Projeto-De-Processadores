-------------------------------------------------------------------------------------------
-- Processador R8 - 2019/1
-- ELC1094 - Projeto de Processadores - Prof. Carara
-- Carlos Gewehr e Emilio Ferreia
-- Verso Atual: 0.1
-------------------------------------------------------------------------------------------
-- Changelog:
-- Carlos - v0.1: Adicionada descrio comportamental do processador R8 
-- Emilio - v0.12: Reajustes de estruturas e processos
-- Emilio - v0.13: Criao da ula separada dos estados
-------------------------------------------------------------------------------------------	   

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;
--use work.R8_pkg.all;

entity R8 is
    port( 
        clk     : in std_logic;
        rst     : in std_logic;
        
        -- Memory interface
        data_in : in std_logic_vector(15 downto 0);
        data_out: out std_logic_vector(15 downto 0);
        address : out std_logic_vector(15 downto 0);
        ce      : out std_logic;
        rw      : out std_logic 
    );
end R8;	 

architecture Behavioural of R8 is

	type State is (Sfetch, Sreg, Shalt, Sula, Swbk, Sld, Sst, Sjmp, Ssbrt, Spush, Srts, Spop, Sldsp);
	type R8Instruction is (
        ADD, SUB, AAND, OOR, XXOR, ADDI, SUBI, NOT_A, 
        SL0, SL1, SR0, SR1,
        LDL, LDH, LD, ST, LDSP, POP, PUSH,
        JUMP_R, JUMP_A, JUMP_D, JSRR, JSR, JSRD,
        NOP, HALT,  RTS
    ); 

    signal currentInstruction : R8Instruction; 
    
	type RegisterArray is array (natural range <>) of std_logic_vector(15 downto 0); 
    type instrucionType is (tipo1, tipo2, outras);
    signal instType  : instrucionType;    -- Instruo tipo 1, tipo 2 ou outra (instruoes sem writeback no banco de registradores)

	signal currentState                : State;
	signal regBank                     : RegisterArray(0 to 15);        -- Banco de registradores	 
    signal regPC                       : std_logic_vector(15 downto 0); -- Program Counter
    signal regIR                       : std_logic_vector(15 downto 0); -- Registrador de Instrues
    signal regSP                       : std_logic_vector(15 downto 0); -- Stack Pointer
    signal regA                        : std_logic_vector(15 downto 0); -- Primeiro reg lido do REGBANK
	signal regB                        : std_logic_vector(15 downto 0); -- Segundo reg lido do REGBANK
	
	signal ALUaux                      : std_logic_vector(16 downto 0); -- Sinal com 16 bits pra lidar com overflow 
    signal regALU                      : std_logic_vector(15 downto 0); -- Registrador ula
    signal outALU                      : std_logic_vector(15 downto 0); -- 

    signal flagN, flagZ, flagC, flagV  : std_logic;                                    -- Flags ALU| negativo, zero, carry, OVFLW

    
	alias OPCODE     : std_logic_vector(3  downto 0) is regIR(15 downto 12);
	alias REGTARGET  : std_logic_vector(3  downto 0) is regIR(11 downto 8);
	alias REGSOURCE1 : std_logic_vector(3  downto 0) is regIR(7  downto 4);
	alias REGSOURCE2 : std_logic_vector(3  downto 0) is regIR(3  downto 0);
	alias CONSTANTE	 : std_logic_vector(7  downto 0) is regIR(7  downto 0);
	alias JMPD_AUX   : std_logic_vector(1  downto 0) is regIR(11 downto 10);
	alias JMPD_DESLOC: std_logic_vector(9  downto 0) is regIR(9  downto 0);
	alias JSRD_DESLOC: std_logic_vector(11 downto 0) is regIR(11 downto 0);
	
begin
	-- Decodificao das instrues
    -- Decodifica o tipo das instrues
    instType <= tipo1 when currentInstruction = ADD  or 
                           currentInstruction = SUB  or
                           currentInstruction = AAND or
                           currentInstruction = OOR  or
                           currentInstruction = XXOR or
                           currentInstruction = SL0  or
                           currentInstruction = SL1  or
                           currentInstruction = SR0  or
                           currentInstruction = SR1  or 
                           currentInstruction = NOT_A else
                           
                tipo2 when currentInstruction = ADDI or
                           currentInstruction = SUBI or
                           currentInstruction = LDL  or
                           currentInstruction = LDH  else
                outras;
                           
    currentInstruction <= ADD    when OPCODE = x"0" else 
                          SUB    when OPCODE = x"1" else
                          AAND   when OPCODE = x"2" else
                          OOR    when OPCODE = x"3" else
                          XXOR   when OPCODE = x"4" else
                          ADDI   when OPCODE = x"5" else
                          SUBI   when OPCODE = x"6" else
                          LDL    when OPCODE = x"7" else
                          LDH    when OPCODE = x"8" else
                          LD     when OPCODE = x"9" else
                          ST     when OPCODE = x"A" else      
					      SL0    when OPCODE = x"B"  and  REGSOURCE2 = x"0" else
				          SL1    when OPCODE = x"B"  and  REGSOURCE2 = x"1" else
                          SR0    when OPCODE = x"B"  and  REGSOURCE2 = x"2" else
				          SR1    when OPCODE = x"B"  and  REGSOURCE2 = x"3" else
                          NOT_A  when OPCODE = x"B"  and  REGSOURCE2 = x"4" else
                          NOP    when OPCODE = x"B"  and  REGSOURCE2 = x"5" else
                          HALT   when OPCODE = x"B"  and  REGSOURCE2 = x"6" else
				          LDSP   when OPCODE = x"B"  and  REGSOURCE2 = x"7" else
				          RTS    when OPCODE = x"B"  and  REGSOURCE2 = x"8" else
				          POP    when OPCODE = x"B"  and  REGSOURCE2 = x"9" else
                          PUSH   when OPCODE = x"B"  and  REGSOURCE2 = x"A" else
                          
                          -- arrumar os pulos condicionais com as falgs
                          JUMP_R when OPCODE = x"C" and (
                                      ( REGSOURCE2 = x"0") or                 -- JMPR
                                      ( REGSOURCE2 = x"1" and flagN = '1') or -- JMPNR
                                      ( REGSOURCE2 = x"2" and flagZ = '1') or -- JMPZR
                                      ( REGSOURCE2 = x"3" and flagC = '1') or -- JMPCR
                                      ( REGSOURCE2 = x"4" and flagV = '1')    -- JMPVR
                          )else
                          JUMP_A when OPCODE = x"C" and (
                                      ( REGSOURCE2 = x"5") or                 -- JMP
                                      ( REGSOURCE2 = x"6" and flagN = '1') or -- JMPN
                                      ( REGSOURCE2 = x"7" and flagZ = '1') or -- JMPZ
                                      ( REGSOURCE2 = x"8" and flagC = '1') or -- JMPC
                                      ( REGSOURCE2 = x"9" and flagV = '1')    -- JMPV
                          )else
                          
                          JUMP_D when OPCODE = x"D" or ( OPCODE = x"E" and (  -- JMPD  
                                      ( JMPD_AUX = "00" and flagN = '1') or   -- JMPND
                                      ( JMPD_AUX = "01" and flagZ = '1') or   -- JMPZD
                                      ( JMPD_AUX = "10" and flagC = '1') or   -- JMPCD
                                      ( JMPD_AUX = "11" and flagV = '1')      -- JMPVD
                                    )
                          )else 
                            
                          JSRR  when OPCODE = x"C"  and  REGSOURCE2 = x"A" else
                          JSR   when OPCODE = x"C"  and  REGSOURCE2 = x"B" else
                          JSRD  when OPCODE = x"F" else
                          NOP; -- Precisa pra n ser perder nos pulos condicionais negativos
                          

                          
	process(clk, rst)
	begin
		if rst = '1' then      
			currentState <= Sfetch;
            -- ADICIONAR O RESTO DOS REGISTRADORES
			regPC <= (others=>'0');
			regSP <= (others=>'0');
            regALU<= (others=>'0');
            regIR <= (others=>'0');
            regA <= (others=>'0');
            regB <= (others=>'0');
            --data_out <= (others=>'0');
            
            for i in 0 to 15 loop     -- zera os registradores
                regBank(i) <= (others => '0');
            end loop;
            
		elsif rising_edge(clk) then
			if currentState = Sfetch then  -- Requests next instruction from memory
				-- Writes next instruction to memory
				regIR <= data_in;
				-- Increments Program Counter		
				regPC <= regPC + 1;                     
				-- Defines next state
				currentState <= Sreg;
                
			elsif currentState = Sreg then 
				-- Reads register bank
				regA <= regBank(to_integer(unsigned(REGSOURCE1)));
				if (instType = tipo2 or currentInstruction = PUSH)then
                    regB <= regBank(to_integer(unsigned(REGTARGET)));
				else
					regB <= regBank(to_integer(unsigned(REGSOURCE2)));
				end if;
                
				-- Defines next state
				if (currentInstruction = HALT) then
					currentState <= Shalt;
				else
					currentState <= Sula;
				end if;
				
			elsif currentState = Shalt then
				-- Idles until next reset (only leaves this state when signal rst = '1')
				currentState <= Shalt;

			elsif currentState = Sula then
				-- utilizao da ULA
                regALU <= outALU;
                
				--Defines next state
				if (instType = tipo1) or (instType = tipo2) then
					currentState <= Swbk;
				elsif currentInstruction = LD then
					currentState <= Sld;
				elsif currentInstruction = ST then
					currentState <= Sst;
				elsif currentInstruction = JUMP_R or currentInstruction = JUMP_A or currentInstruction = JUMP_D then
					currentState <= Sjmp;
				elsif (currentInstruction = JSR) or (currentInstruction = JSRR) or (currentInstruction = JSRD) then
					currentState <= Ssbrt;
				elsif currentInstruction = PUSH then
					currentState <= Spush;
				elsif currentInstruction = RTS then
					currentState <= Srts;
				elsif currentInstruction = POP then
					currentState <= Spop;
				elsif currentInstruction = LDSP then
					currentState <= Sldsp;
				else
					currentState <= Sfetch;
				end if;
				
                
			elsif currentState = Swbk then -- Ultimo ciclo de instrues logicas e aritmeticas
				regBank(to_integer(unsigned(REGTARGET))) <= regALU;
				currentState <= Sfetch;
                
			elsif currentState = Sld then -- Ultimo ciclo de load
				regBank(to_integer(unsigned(REGTARGET))) <= data_in;
				currentState <= Sfetch;
                
			elsif currentState = Sst then -- Ultimo ciclo de store
                --data_out <= regA; torar o data out do process
				currentState <= Sfetch;
                
			elsif currentState = Sjmp then -- Ultimo ciclo p/ saltos
                regPC <= regALU; -- Atualiza o pc
				currentState <= Sfetch;
                
			elsif currentState = Ssbrt then -- Ultimo ciclo Subrotina                             
                regPC <= regALU;       
                regSP <= regSP - 1; 
				currentState <= Sfetch;
                
			elsif currentState = Spush then -- Ultimo ciclo p push
                regSP <= regSP - 1;
                --data_out <= regA;
				currentState <= Sfetch;
                
			elsif currentState = Srts then -- Ultimo cilco retorno subronita
                --regSP <= regSP + 1;
                regPC <= data_in; -- volta o pc da oulha
				currentState <= Sfetch;
                
			elsif currentState = Spop then -- Ultimo ciclo de POP
                regSP <= regSP + 1;
                regBank(to_integer(unsigned(REGTARGET)))<= data_in; --banco de registdadores enderaado <= mem pelo SP
				currentState <= Sfetch;
                
			elsif currentState = Sldsp then -- Yltimo ciclo de load do sp
                regSP  <= regALU;
				currentState <= Sfetch;
            else
                currentState <= Shalt;
			end if;			
		end if;
	end process;
    
    -- Flags para a ULA
	
	ALUaux <= ('0' & regA) + ('0' & regB) when currentInstruction = ADD else
			  ('0' & regA) + ('0' & ((not(regB))+1)) when currentInstruction = SUB else
			  ('0' & regB) + ('0' & x"00" & CONSTANTE) when currentInstruction = ADDI else
			  ('0' & regB) + ((not('0' & x"00" & CONSTANTE))+1) when currentInstruction = SUBI else
              (others => '0');
    
    outALU <= ALUaux(15 downto 0) when (currentInstruction = ADD or currentInstruction = SUB or currentInstruction = ADDI or currentInstruction = SUBI) else 
              regA and regB when currentInstruction = AAND else
              regA or regB when currentInstruction = OOR else
              regA xor regB when currentInstruction = XXOR else
              regB(15 downto 8) & CONSTANTE when currentInstruction = LDL else
              CONSTANTE & regB(7 downto 0) when currentInstruction = LDH else
              regA + regB when currentInstruction = LD else --rt <= PMEM (Rs1 + Rs2)
              regA + regB when currentInstruction = ST else -- PMEM (Rs1 + Rs2) <- rt
              regA(14 downto 0) & '0' when  currentInstruction = SL0 else
              regA(14 downto 0) & '1' when  currentInstruction = SL1 else
              '0' & regA(15 downto 1) when currentInstruction = SR0 else
              '1' & regA(15 downto 1) when currentInstruction = SR1 else
              not(regA) when currentInstruction = NOT_A else
              regSP + 1 when currentInstruction = RTS or currentInstruction = POP else
              regPC + regA when currentInstruction = JUMP_R else
              regPC + (JMPD_DESLOC(9)&JMPD_DESLOC(9)&JMPD_DESLOC(9)&JMPD_DESLOC(9)&JMPD_DESLOC(9)&JMPD_DESLOC(9)&JMPD_DESLOC) when currentInstruction = JUMP_D else
              regPC + (JSRD_DESLOC(11) & JSRD_DESLOC(11) & JSRD_DESLOC(11) & JSRD_DESLOC(11) & JSRD_DESLOC) when currentInstruction = JSRD else
              regPC + regA when currentInstruction = JSR else
              regA; -- JMP_A, JSR, LDSP
            
                          
    flagC <= ALUaux(16) when (currentInstruction = ADD or currentInstruction = ADDI or currentInstruction = SUB or currentInstruction = SUBI) else '0';--carry
    flagV <= '1' when (regA(15) = regB(15) and regA(15) /= outALU(15)) and (currentInstruction = ADD or currentInstruction = ADDI or currentInstruction = SUB or currentInstruction = SUBI) else '0' ; -- overflow
    flagN <= outALU(15) when (instType = tipo1 or currentInstruction = ADDI or currentInstruction = SUBI) else '0'; -- negativo
    flagZ <= '1' when outALU = 0 and (instType = tipo1 or currentInstruction = ADDI or currentInstruction = SUBI) else '0';  -- zero
      
    address <= regPC when currentState = Sfetch else
               --outALU when currentState = Sld or currentState = Sst or currentState = Spop or currentState = Srts else
               regALU when currentState = Sld or currentState = Sst or currentState = Spop or currentState = Srts else
               regSP; -- Pra dar salto em uma subrotina e o PUSH
                    
    data_out <= regBank(to_integer(unsigned(REGTARGET))) when currentState = Sst else --Pmem(RS1 + Rs2) <= RT
                regPC when currentState = Ssbrt else
                regB when currentState = Spush else
                (others => '0');              
    
    -- SINAIS MEMORIA
    ce <= '1' when rst = '0' and (currentState = Sld or currentState = Ssbrt or currentState = Spush or currentState = Sst or currentState = Sfetch or currentState = Srts or currentState = Spop) else '0';
    rw <= '1' when (currentState = Sfetch or currentState = Spop or currentState = Srts or currentState = Sld) else '0';
end Behavioural;


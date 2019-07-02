-------------------------------------------------------------------------------------------
-- Processador R8 - 2019/1
-- ELC1094 - Projeto de Processadores - Prof. Carara
-- Carlos Gewehr e Emilio Ferreia
-- Verso Atual: 0.2
-------------------------------------------------------------------------------------------
-- Changelog:
-- Carlos - v0.1: Adicionada descrio comportamental do processador R8
-- Emilio - v0.12: Reajustes de estruturas e processos
-- Emilio - v0.13: Criação da ula separada dos estados
-- Carlos - v0.2: Adicionadas instruçoes PUSHF, POPF e RTI, e suporte para interrupções
-- Carlos - v0.21: Adicionada instrução LDISRA
-- Carlos - v0.3: Adicionadas instruções MFC, MFT, SYSCALL, LDTSRA, e suporte para traps
-- Carlos - v0.31: Recodificação das instruções de jump
-------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_signed.all;
use IEEE.numeric_std.all;

entity R8 is
    port(
		-- 50 MHz clock from DCM
        clk       : in std_logic;

		-- From reset synchronizer
        rst       : in std_logic;

		-- Peripheral interrupt flag
        irq       : in std_logic;
        
        -- RAM programming flag
        prog_mode : in std_logic;

        -- Memory interface
        data_in   : in std_logic_vector(15 downto 0);
        data_out  : out std_logic_vector(15 downto 0);
        address   : out std_logic_vector(15 downto 0);
        ce        : out std_logic;
        rw        : out std_logic
    );
end R8;

architecture Behavioural of R8 is

    type State is (Sfetch, Sreg, Shalt, Sula, Swbk, Sld, Sst, Sjmp, Ssbrt, Spush, Srts, Spop, Sldsp, Spushf, Spopf, Srti, Sitr, Smul, Sdiv, Smfh, Smfl, Sldisra, Sldtsra, Smfc, Smft, Ssyscall, Strap);
    type R8Instruction is (
            ADD, SUB, AAND, OOR, XXOR, ADDI, SUBI, NOT_A,
            SL0, SL1, SR0, SR1,
            LDL, LDH, LD, ST, LDSP, POP, PUSH,
            JMPR, JMPNR, JMPZR, JMPCR, JMPVR, --JUMP_R
            JMP, JMPN, JMPZ, JMPC, JMPV,      --JUMP_A
            JMPD, JMPND, JMPZD, JMPCD, JMPVD, --JUMP_D
            JSRR, JSR, JSRD,
            NOP, HALT,  RTS,

            -- Novas instruções T3P2
		    PUSHF, POPF, RTI,

		    -- Novas instruções T4P1
		    MUL, DIV, MFH, MFL,

            -- Nova Instrução T4P2
            LDISRA,

            -- Novas Instruções T5P2
            MFC, MFT, SYSCALL, LDTSRA,

            INVALID
    );

    type RegisterArray is array (natural range <>) of std_logic_vector(15 downto 0);
    type instrucionType is (tipo1, tipo2, outras);

	signal currentInstruction          : R8Instruction;
	signal currentState                : State;
	signal instType                    : instrucionType;                -- Instrução tipo 1, tipo 2 ou outra (instruçoes sem writeback no banco de registradores)

	-- Registradores do Processador
    signal regBank                     : RegisterArray(0 to 15);        -- Banco de registradores
    signal regPC                       : std_logic_vector(15 downto 0); -- Program Counter
    signal regIR                       : std_logic_vector(15 downto 0); -- Instrução sendo executada
    signal regSP                       : std_logic_vector(15 downto 0); -- Stack Pointer
    signal regA                        : std_logic_vector(15 downto 0); -- Primeiro reg lido do banco de registradores
	signal regB                        : std_logic_vector(15 downto 0); -- Segundo reg lido do banco de registradores
	signal regALU                      : std_logic_vector(15 downto 0); -- Registrador ALU
  	signal regHIGH                     : std_logic_vector(15 downto 0); -- Registrador HIGH para MUL/DIV (Parte Alta)
  	signal regLOW                      : std_logic_vector(15 downto 0); -- Registrador LOW para MUL/DIV (Parte Baixa)
    signal regISRA                     : std_logic_vector(15 downto 0); -- Registrador que contem o endereço da subrotina de tratamento de interrupção
    signal regTSRA                     : std_logic_vector(15 downto 0); -- Registrador que contem o endereço da subrotina de tratamento de traps
    signal regCAUSE                    : std_logic_vector(15 downto 0); -- Registrador com causa da trap
    signal regITR                      : std_logic_vector(15 downto 0); -- Registrador com endereço de instrução causante de trap/instrução interrompida

	-- Sinais combinacionais pra ALU
    signal ALUaux                      : std_logic_vector(16 downto 0); -- Sinal com 17 bits pra lidar com overflow (soma de sinais de 16 bits)
    signal outALU                      : std_logic_vector(15 downto 0);
    signal multiplicador               : std_logic_vector(31 downto 0);
    signal divisor                     : std_logic_vector(31 downto 0);
	signal regBComplement              : std_logic_vector(15 downto 0);
	signal constanteExtended           : std_logic_vector(15 downto 0);
	signal constanteComplement         : std_logic_vector(15 downto 0);

	-- Registrador de Flags
    signal regFLAGS                    : std_logic_vector(3 downto 0);
    alias n                            : std_logic is regFLAGS(3);
    alias z                            : std_logic is regFLAGS(2);
    alias c                            : std_logic is regFLAGS(1);
    alias v                            : std_logic is regFLAGS(0);

    -- Sinais auxiliares para geração de flags, atualizados combinacionalmente na ALU
    signal flagN, flagZ, flagC, flagV  : std_logic; -- Flags ALU| negativo, zero, carry, OVFLW

	-- Campos do registrador de instrução
	alias OPCODE                       : std_logic_vector( 3 downto 0) is regIR(15 downto 12);
	alias REGTARGET                    : std_logic_vector( 3 downto 0) is regIR(11 downto  8);
	alias REGSOURCE1                   : std_logic_vector( 3 downto 0) is regIR( 7 downto  4);
	alias REGSOURCE2                   : std_logic_vector( 3 downto 0) is regIR( 3 downto  0);
	alias CONSTANTE                    : std_logic_vector( 7 downto 0) is regIR( 7 downto  0);
	alias JMPD_AUX                     : std_logic_vector( 1 downto 0) is regIR(11 downto 10);
	alias JMPD_DESLOC                  : std_logic_vector( 9 downto 0) is regIR( 9 downto  0);
	alias JSRD_DESLOC                  : std_logic_vector(11 downto 0) is regIR(11 downto  0);

	signal interruptFlag               : std_logic; -- Signals if processor is currently treating an interruption
    signal trapCount                   : integer;   -- Signals if processor is currently treating a trap
    signal newTrapFlag                 : std_logic; -- Signals if processor generated a new untreated trap

  signal nullPointerExceptionFlag    : std_logic; -- Signals if processor is trying to read/write data (not reading an instruction) @ memory position 0
begin

    -- Decodifica o tipo das instruçoes
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

    -- Decodifica instruçoes
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

						  -- Novas Instruções T4P1
						  MUL    when OPCODE = x"B" and REGSOURCE2 = x"B" else  -- MULTIPLICAÇÃO
                          DIV    when OPCODE = x"B" and REGSOURCE2 = x"C" else  -- DIVISÃO
                          MFH    when OPCODE = x"B" and REGSOURCE2 = x"D" else  -- MOVE FROM HIGH
                          MFL    when OPCODE = x"B" and REGSOURCE2 = x"E" else  -- MOVE FROM LOW

                          -- Nova Instrução T4P2
                          LDISRA when OPCODE = x"B" and REGSOURCE2 = x"F" else  -- LOAD ISR ADDR

                          JMPR   when OPCODE = x"C" and REGTARGET = x"0" and REGSOURCE2 = x"0" else
                          JMPNR  when OPCODE = x"C" and REGTARGET = x"0" and REGSOURCE2 = x"1" else
                          JMPZR  when OPCODE = x"C" and REGTARGET = x"0" and REGSOURCE2 = x"2" else
                          JMPCR  when OPCODE = x"C" and REGTARGET = x"0" and REGSOURCE2 = x"3" else
                          JMPVR  when OPCODE = x"C" and REGTARGET = x"0" and REGSOURCE2 = x"4" else

                          JMP    when OPCODE = x"C" and REGTARGET = x"0" and REGSOURCE2 = x"5" else
                          JMPN   when OPCODE = x"C" and REGTARGET = x"0" and REGSOURCE2 = x"6" else
                          JMPZ   when OPCODE = x"C" and REGTARGET = x"0" and REGSOURCE2 = x"7" else
                          JMPC   when OPCODE = x"C" and REGTARGET = x"0" and REGSOURCE2 = x"8" else
                          JMPV   when OPCODE = x"C" and REGTARGET = x"0" and REGSOURCE2 = x"9" else

                          JMPD   when OPCODE = x"D" and JMPD_AUX = "00" else
                          JMPND  when OPCODE = x"E" and JMPD_AUX = "00" else
                          JMPZD  when OPCODE = x"E" and JMPD_AUX = "01" else
                          JMPCD  when OPCODE = x"E" and JMPD_AUX = "10" else
                          JMPVD  when OPCODE = x"E" and JMPD_AUX = "11" else

                          JSRR   when OPCODE = x"C" and REGTARGET = x"0" and REGSOURCE2 = x"A" else
                          JSR    when OPCODE = x"C" and REGTARGET = x"0" and REGSOURCE2 = x"B" else
                          JSRD   when OPCODE = x"F" else

                          -- Novas Instruções T3P2
                          PUSHF  when OPCODE = x"C" and REGTARGET = x"0" and REGSOURCE2 = x"C" else  -- PUSH FLAGS
			              POPF   when OPCODE = x"C" and REGTARGET = x"0" and REGSOURCE2 = x"D" else  -- POP FLAGS
			              RTI    when OPCODE = x"C" and REGTARGET = x"0" and REGSOURCE2 = x"E" else  -- RETORNO DE INTERRUPCAO

                          -- Novas Instruções T5P2
                          SYSCALL when OPCODE = x"C" and REGTARGET = x"1" else
                          LDTSRA  when OPCODE = x"C" and REGTARGET = x"2" else
                          MFC     when OPCODE = x"C" and REGTARGET = x"3" else
                          MFT     when OPCODE = x"C" and REGTARGET = x"4" else


                          INVALID;

    process(clk, rst) begin

		if rst = '1' then
			regPC    <= (others=>'0');
			regSP    <= (others=>'0');
            regALU   <= (others=>'0');
            regIR    <= (others=>'0');
            regA     <= (others=>'0');
            regB     <= (others=>'0');
			regFLAGS <= (others=>'0');
			regHIGH  <= (others=>'0');
			regLOW   <= (others=>'0');
            regISRA  <= (others=>'0');
            regTSRA  <= (others=>'0');
            regCAUSE <= (others=>'0');
            regITR   <= (others=>'0');

            for i in 0 to 15 loop
                regBank(i) <= (others => '0');
            end loop;

			interruptFlag <= '0';
            newTrapFlag <= '0';
            trapCount <= 0;

            currentState <= Sfetch;

		elsif rising_edge(clk) then

		    if currentState = Sfetch then  -- Requests next instruction from memory

				if newTrapFlag = '1' then
                    -- Defines next state
					currentState <= Strap;

                    -- Saves address of instruction being executed (before interruption/trap)
                    regITR <= regPC;

                elsif irq = '1' and interruptFlag = '0' then
                    -- Defines next state
                    currentState <= Sitr;

                    -- Saves address of instruction being executed (before interruption/trap)
                    regITR <= regPC;

			    else
			    	-- Defines next state
					currentState <= Sreg;
					regIR <= data_in;

                    -- Increments Program Counter
                    regPC <= regPC + 1;

				end if;

            elsif currentState = Strap then
                -- Saves PC on stack
                regSP <= regSP - 1;

                -- InterruptFlag stays active until RTI instruction is executed (cant be interrupted by peripheral)
                interruptFlag <= '1';
                newTrapFlag <= '0';
                trapCount <= trapCount + 1;

                -- Next instruction is the first instruction on the TSR subroutine
                regPC <= regTSRA; -- Trap (exception/syscall, generated by software)

                -- Fetches first instruction of TSR subroutine
                currentState <= Sfetch;

            elsif currentState = Sitr then
                -- Saves PC on stack
                regSP <= regSP - 1;

                -- InterruptFlag stays active until RTI instruction is executed
                interruptFlag <= '1';

                -- Next instruction is the first instruction on the ISR subroutine
                regPC <= regISRA; -- Interruption (generated by peripheral/hardware)

                -- Fetches first instruction of ISR subroutine
                currentState <= Sfetch;

        	elsif currentState = Sreg then

                if currentInstruction = INVALID then
                    --regCAUSE <= to_unsigned(std_logic_vector(1, regCAUSE'length)); -- Throws Invalid Instruction
                    regCAUSE <= std_logic_vector(to_unsigned(1, regCAUSE'length)); -- Throws Invalid Instruction
                    newTrapFlag <= '1';
                    currentState <= Sfetch;
                elsif currentInstruction = HALT then
                    currentState <= Shalt;
                else
                    -- Reads register bank
                    regA <= regBank(to_integer(unsigned(REGSOURCE1)));

                    if (instType = tipo2 or currentInstruction = PUSH or currentInstruction = MUL or currentInstruction = DIV) then
                        regB <= regBank(to_integer(unsigned(REGTARGET)));
                    else
                        regB <= regBank(to_integer(unsigned(REGSOURCE2)));
                    end if;

                    currentState <= Sula;
        		end if;

        	elsif currentState = Shalt then
        		-- Idles until next reset (only leaves this state when signal rst = '1' or irq = '1')
                if irq = '1' and interruptFlag = '0' then
                    currentState <= Sitr;
                    regPC <= regPC - 1; -- In order to remain on halt on return from interruption
                else
                    currentState <= Shalt;
                end if;

        	elsif currentState = Sula then
        		-- Utilização da ALU
                regALU <= outALU;

                --Geração de flag
                if currentInstruction = ADD or currentInstruction = SUB or currentInstruction = ADDI or currentInstruction = SUBI then
                    v <= flagV; -- Flag de overflow
                    c <= flagC; -- Flag de carry
                end if;

                if (instType = tipo1) or (currentInstruction = ADDI or currentInstruction = SUBI) then
                    n <= flagN; -- Flag de negativo
                    z <= flagZ; -- Flag de zero
                end if;

          		--Defines next state
          		if (instType = tipo1) or (instType = tipo2) then
          			currentState <= Swbk;
          		elsif currentInstruction = LD then
          			currentState <= Sld;
          		elsif currentInstruction = ST then
          			currentState <= Sst;
          		elsif currentInstruction = JMPR or currentInstruction = JMPNR or currentInstruction = JMPZR or currentInstruction = JMPCR or currentInstruction = JMPVR or
                      currentInstruction = JMP or currentInstruction = JMPN or currentInstruction = JMPZ or currentInstruction = JMPC or currentInstruction = JMPV or
                      currentInstruction = JMPD or currentInstruction = JMPND or currentInstruction = JMPZD or currentInstruction = JMPCD or currentInstruction = JMPVD then

              		if currentInstruction = JMPR or currentInstruction = JMP or currentInstruction = JMPD then
                        currentState <= Sjmp;
                    elsif (currentInstruction = JMPNR or currentInstruction = JMPN or currentInstruction = JMPND) and n = '1' then
                        currentState <= Sjmp;
                    elsif (currentInstruction = JMPZR or currentInstruction = JMPZ or currentInstruction = JMPZD) and z = '1' then
                        currentState <= Sjmp;
                    elsif (currentInstruction = JMPCR or currentInstruction = JMPC or currentInstruction = JMPCD) and c = '1' then
                        currentState <= Sjmp;
                    elsif (currentInstruction = JMPVR or currentInstruction = JMPV or currentInstruction = JMPVD) and v = '1' then
                        currentState <= Sjmp;
                    else
                        currentState <= Sfetch;
                    end if;

          		elsif currentInstruction = JSR or currentInstruction = JSRR or currentInstruction = JSRD then
          			currentState <= Ssbrt;
          		elsif currentInstruction = PUSH then
          			currentState <= Spush;
          		elsif currentInstruction = RTS then
          			currentState <= Srts;
          		elsif currentInstruction = POP then
          		 	currentState <= Spop;
          		elsif currentInstruction = LDSP then
          			currentState <= Sldsp;

          		-- NOVAS INSTRUÇOES T3P2
          		elsif currentInstruction = PUSHF then
          			currentState <= Spushf;
          		elsif currentInstruction = POPF then
          			currentState <= Spopf;
          		elsif currentInstruction = RTI then
          			currentState <= Srti;

          		-- NOVAS INSTRUÇÔES T4P1
          		elsif currentInstruction = MUL then
          			currentState <= Smul;
          		elsif currentInstruction = DIV then
          			currentState <= Sdiv;
          		elsif currentInstruction = MFH then
          		    currentState <= Smfh;
          		elsif currentinstruction = MFL then
          			currentState <= Smfl;

                -- NOVA INSTRUÇÂO T4P2
                elsif currentInstruction = LDISRA then
                    currentState <= Sldisra;

                -- NOVAS INSTRUÇÔES T5P2
                elsif currentInstruction = LDTSRA then
                    currentState <= Sldtsra;
                elsif currentInstruction = MFC then
                    currentState <= Smfc;
                elsif currentInstruction = MFT then
                    currentState <= Smft;
                elsif currentInstruction = SYSCALL then
                    currentState <= Ssyscall;

          		else
          			currentState <= Sfetch;
          		end if;

    	    elsif currentState = Swbk then -- Ultimo ciclo de instrues logicas e aritmeticas

                if (currentinstruction = ADD or currentinstruction = ADDI or currentinstruction = SUB or currentinstruction = SUBI) then
                    if v = '1' then
                        regCAUSE <= std_logic_vector(to_unsigned(12, regCAUSE'length)); -- Throws Overflow
                        newTrapFlag <= '1';
                        currentState <= Sfetch;
                    else
                        regBank(to_integer(unsigned(REGTARGET))) <= regALU;
                        currentState <= Sfetch;
                    end if;
                else
                    regBank(to_integer(unsigned(REGTARGET))) <= regALU;
                    currentState <= Sfetch;
                end if;

    		elsif currentState = Sld then -- Ultimo ciclo de load
		        if nullPointerExceptionFlag = '1' then
		            regCAUSE <= std_logic_vector(to_unsigned(0, regCAUSE'length)); -- Throws NullPointerException
		            newTrapFlag <= '1';
		            currentState <= Sfetch;
		        else
		    		regBank(to_integer(unsigned(REGTARGET))) <= data_in;
		    		currentState <= Sfetch;
		        end if;

    		elsif currentState = Sst then -- Ultimo ciclo de store
         		if nullPointerExceptionFlag = '1' then
          			regCAUSE <= std_logic_vector(to_unsigned(0, regCAUSE'length)); -- Throws NullPointerException
           			newTrapFlag <= '1';
            		currentState <= Sfetch;
          		else
    			 	currentState <= Sfetch;
          		end if;

    		elsif currentState = Sjmp then -- Ultimo ciclo p/ saltos
                regPC <= regALU;
                currentState <= Sfetch;

    		elsif currentState = Ssbrt then -- Ultimo ciclo Subrotina
                regPC <= regALU; -- Atualiza o PC
                regSP <= regSP - 1;
    			currentState <= Sfetch;

    		elsif currentState = Spush then -- Ultimo ciclo p push
                regSP <= regSP - 1;      -- Adicionado na apresentação
    			currentState <= Sfetch;

    		elsif currentState = Srts then -- Ultimo ciclo retorno subronita
                regSP <= regSP + 1;
                regPC <= data_in; -- Volta o PC da pilha
    			currentState <= Sfetch;

    		elsif currentState = Spop then -- Ultimo ciclo de POP
                regSP <= regSP + 1;
                regBank(to_integer(unsigned(REGTARGET))) <= data_in; -- Banco de registradores enderaçado <= mem pelo SP
    			currentState <= Sfetch;

    		elsif currentState = Sldsp then -- Ultimo ciclo de load do SP
                regSP <= regALU;
    			currentState <= Sfetch;

    		-- NOVAS INSTRUÇOES T3P2
    		elsif currentState = Spushf then
    			regSP <= regSP - 1;
    			currentState <= Sfetch;

    		elsif currentState = Spopf then
    			regSP <= regSP + 1;
    			regFLAGS <= data_in(3 downto 0);
    			currentState <= Sfetch;

    		elsif currentState = Srti then
    			regSP <= regSP + 1;
    			regPC <= data_in;

                if trapCount > 0 then
                    trapCount <= trapCount - 1;  -- Decreases trap stack
                end if;
                                                             
                if trapCount <= 1 then
                    interruptFlag <= '0';        -- Enables I/O interruptions again if trap stack is = 0 (accounting for asynchronous decrease made above)
                end if;

    			currentState <= Sfetch;

    		-- NOVAS INSTRUÇÔES T4P1
    		elsif currentState = Smul then
    			regHIGH <= multiplicador(31 downto 16);
    			regLOW <= multiplicador(15 downto 0);
    			currentState <= Sfetch;

    		elsif currentState = Sdiv then
                if regA /= 0 then
    			    regHIGH <= divisor(31 downto 16);
    			    regLOW <= divisor(15 downto 0);
                else
                    regCAUSE <= std_logic_vector(to_unsigned(15, regCAUSE'length)); -- Throws Division By Zero
                    newTrapFlag <= '1';
                end if;

    			currentState <= Sfetch;

    		elsif currentState = Smfh then
    			regBank(to_integer(unsigned(REGTARGET))) <= regHIGH;
    			currentState <= Sfetch;

    		elsif currentState = Smfl then
    			regBank(to_integer(unsigned(REGTARGET))) <= regLOW;
    			currentState <= Sfetch;

            -- NOVA INSTRUÇÂO T4P2
            elsif currentState = Sldisra then
                regISRA <= regBank(to_integer(unsigned(REGSOURCE1)));
                currentState <= Sfetch;

            -- NOVAS INSTRUÇÕES T5P2
            elsif currentState = Smfc then
                regBank(to_integer(unsigned(REGSOURCE1))) <= regCAUSE;
                currentState <= Sfetch;

            elsif currentState = Smft then
                regBank(to_integer(unsigned(REGSOURCE1))) <= regITR;
                currentState <= Sfetch;

            elsif currentState = Sldtsra then
                regTSRA <= regBank(to_integer(unsigned(REGSOURCE1)));
                currentState <= Sfetch;

            elsif currentState = Ssyscall then
                regCAUSE <= std_logic_vector(to_unsigned(8, regCAUSE'length));
                newTrapFlag <= '1';
                currentState <= Sfetch;
            else
                currentState <= Shalt;
    		end if;
    	end if;
    end process;

	multiplicador <= (regA * regB) when currentinstruction = MUL else (others=>'0');

	divisor(31 downto 16) <= STD_LOGIC_VECTOR ( UNSIGNED(regB) mod UNSIGNED(regA) ) when (currentInstruction = DIV and regA/= 0) else (others=>'0');
	divisor(15 downto 0)  <= STD_LOGIC_VECTOR ( SIGNED(regB) / SIGNED(regA) )       when (currentInstruction = DIV and regA/= 0) else (others=>'0');

	--ALUaux <= ( '0' & regA) + ( '0' & regB) when currentInstruction = ADD else
	--		  ( '0' & regA) + ( '0' & ((not(regB))+1)) when currentInstruction = SUB else
	--		  ( '0' & regB) + ( '0' & x"00" & CONSTANTE) when currentInstruction = ADDI else
	--		  ( '0' & regB) + ((not( '0' & x"00" & CONSTANTE))+1); -- when currentInstruction = SUBI; GENERATES LATCH IF UNCOMMENTED

	constanteExtended(15 downto 8) <= (others=>CONSTANTE(7));
	constanteExtended(7 downto 0)  <= (CONSTANTE);
	constanteComplement <= ( ( not constanteExtended ) + 1 );

	regBComplement <= ( (not regB) + 1 ); -- Twos complement of regB

	ALUaux <= ( regA(15) & regA ) + ( regB(15) & regB )                                when currentInstruction = ADD else
			  ( regA(15) & regA ) + ( regBComplement(15) & regBComplement )            when currentinstruction = SUB else
			  ( regB(15) & regB ) + ( constanteExtended(15) & constanteExtended)       when currentInstruction = ADDI else
			  ( regB(15) & regB ) + ( constanteComplement(15) & constanteComplement);-- when currentInstruction = SUBI; GENERATES LATCHES IF UNCOMMENTED

    outALU <= ALUaux(15 downto 0)           when currentInstruction = ADD or currentInstruction = SUB or currentInstruction = ADDI or currentInstruction = SUBI else
              regA and regB                 when currentInstruction = AAND else
              regA or regB                  when currentInstruction = OOR else
              regA xor regB                 when currentInstruction = XXOR else
              regB(15 downto 8) & CONSTANTE when currentInstruction = LDL else
              CONSTANTE & regB(7 downto 0)  when currentInstruction = LDH else
              regA + regB                   when currentInstruction = LD else -- rt <= PMEM (Rs1 + Rs2)
              regA + regB                   when currentInstruction = ST else -- PMEM (Rs1 + Rs2) <- rt
              regA(14 downto 0) & '0'       when currentInstruction = SL0 else
              regA(14 downto 0) & '1'       when currentInstruction = SL1 else
              '0' & regA(15 downto 1)       when currentInstruction = SR0 else
              '1' & regA(15 downto 1)       when currentInstruction = SR1 else
              not(regA)                     when currentInstruction = NOT_A else
              regSP + 1                     when currentInstruction = RTS or currentInstruction = POP or currentInstruction = POPF or currentInstruction = RTI else
              regPC + regA                  when currentInstruction = JMPR or currentInstruction = JMPNR or currentInstruction = JMPZR or currentInstruction = JMPCR or currentInstruction = JMPVR else
              regPC + (JMPD_DESLOC(9) & JMPD_DESLOC(9) & JMPD_DESLOC(9) & JMPD_DESLOC(9) & JMPD_DESLOC(9) & JMPD_DESLOC(9) & JMPD_DESLOC)
              								when currentInstruction = JMPD or currentInstruction = JMPND or currentInstruction = JMPZD or currentInstruction = JMPCD or currentInstruction = JMPVD else
              regPC + (JSRD_DESLOC(11) & JSRD_DESLOC(11) & JSRD_DESLOC(11) & JSRD_DESLOC(11) & JSRD_DESLOC) when currentInstruction = JSRD else
              regA                          when currentInstruction = JSR or currentInstruction = JSRR else
              regA; -- JMP_A, LDSP

    -- Flags para a ULA
    flagC <= ALUaux(16); --carry
    --flagV <= '1' when ( ( ( currentInstruction = ADD  or currentInstruction = SUB)  and ( ( regA(15) = regB(15) ) and ( regA(15) /= outALU(15))))  or
    flagV <= '1' when ( ( ( currentInstruction = ADD  ) and ( regA(15) = regB(15) ) and ( regA(15) /= outALU(15) ) )  or
                        ( ( currentInstruction = SUB  ) and ( regA(15) = regBComplement(15) ) and ( regA(15) /= outALU(15) ) )  or
                        ( ( currentInstruction = ADDI ) and ( regB(15) = constanteExtended(15) ) and ( regB(15) /= outALU(15) ) )  or
                        ( ( currentInstruction = SUBI ) and ( regB(15) = constanteComplement(15) ) and ( regB(15) /= outALU(15) ) ) ) 
                        else '0';
                       
--    flagV <= '1' when ( ( ( currentInstruction = ADD ) and ( regA(15) = regB(15) ) ) or 
--                        ( ( currentInstruction = SUB ) and ( regA(15) = regBComplement(15) ) ) or 
--                        ( ( currentInstruction = ADDI ) and ( regB(15) = constanteExtented(15) ) ) or
--                        ( ( currentInstruction = SUBI ) and ( regB(15) = constanteComplement(15) ) ) ) and ( regA(15) /= outALU(15) ) else '0';
--                   
    --flagV <= '1' when ( (regA(15) = regB(15) ) and ( regA(15) /= outALU(15) ) ) else '0'; -- overflow
    flagN <= outALU(15); -- negativo
    flagZ <= '1' when outALU = 0 else '0';  -- zero

    -- SINAIS MEMORIA
    address <= regPC when currentState = Sfetch else
               --outALU when currentState = Sld or currentState = Sst or currentState = Spop or currentState = Srts else
               regALU when currentState = Sld or currentState = Sst or currentState = Spop or currentState = Srts or currentState = Spopf or currentState = Srti else
               regSP; -- Pra dar salto em uma subrotina e o PUSH (Spushf, Spush, Sitr, Strap)

    data_out <= regBank(to_integer(unsigned(REGTARGET))) when currentState = Sst and rst = '0' else
                regB when currentState = Spush and rst = '0' else
                regPC when currentState = Ssbrt and rst = '0' else
				( "000000000000" & regFLAGS ) when currentState = Spushf and rst = '0' else
				regPC when currentState = Sitr and rst = '0' else
                regPC when currentState = Strap and rst = '0' else
                (others=>'0');

    ce <= '1' when rst = '0' and ( ( currentState = Sld and ( ( regALU /= 0 and prog_mode = '0' ) or ( prog_mode = '1' ) ) ) or currentState = Ssbrt or currentState = Spush or 
      ( currentState = Sst and ( ( regALU /= 0 and prog_mode = '0' ) or ( prog_mode = '1' ) ) ) or currentState = Sfetch or currentState = Srts or currentState = Spop or currentState = Spopf or currentState = Spushf or currentState = Sitr or currentState = Strap or currentState = Srti ) else '0';

    rw <= '1' when (currentState = Sfetch or currentState = Spop or currentState = Srts or currentState = Sld or currentState = Spopf or currentState = Srti) else '0';

    nullPointerExceptionFlag <= '1' when ( (currentState = Sld or currentState = Sst) and regALU = 0 and prog_mode = '0') else '0'; -- Active when Loading/Storing into/to first memory position in execution mode

end Behavioural;

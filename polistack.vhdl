library ieee;
use ieee.numeric_bit.all;

entity d_register is
    generic (
        width : natural := 4;
        reset_value : natural := 0
    );
    port (
        clock, reset, load : in bit;
        d : in bit_vector(width-1 downto 0);
        q : out bit_vector(width-1 downto 0)
    );
end entity d_register;

architecture behavior of d_register is
begin
    p0: process(clock, reset, load)
    begin 
        if reset = '1' then
            q <= bit_vector(to_unsigned(reset_value, width));
        elsif load = '1' and clock'event and clock = '1' then
            q <= d;
        end if;
    end process p0;
end architecture behavior;

--------------------------------------------------------------------------------

    library ieee;
    use ieee.numeric_bit.all;

    entity alu is
        generic (
            size : natural := 8
        );
        port (
            A, B : in bit_vector(size-1 downto 0); -- inputs
            F    : out bit_vector(size-1 downto 0); -- output
            S    : in bit_vector(2 downto 0); -- op selection
            Z    : out bit; -- zero flag
            Ov   : out bit; -- overflow flag
            Co   : out bit -- carry out
        );
    end entity alu;

    entity bitOperation is
        port (
            A, B : in bit; -- inputs
            F    : out bit; -- output
            S    : in bit_vector(2 downto 0); -- op selection
            Ci   : in bit; -- carry in
            Co   : out bit -- carry out
        );
    end entity bitOperation;

    architecture whenElse of bitOperation is
        signal Bnot : bit;
    begin
        Bnot <= not B;
        F <= A                    when S = "000" else
            A xor B xor Ci       when S = "001" else
            A and B              when S = "010" else
            A or B               when S = "011" else
            A xor Bnot xor Ci    when S = "100" else
            not A                when S = "101" else
            A                    when S = "110" else
            B                    when S = "111";

        Co <=  (A and B)    or (B and Ci)    or (Ci and A)  when S = "001" else
            ((A and Bnot) or (Bnot and Ci) or (Ci and A)) when S = "100" else
            '0';
    end architecture whenElse;

    architecture combinatory of alu is

        component bitOperation
            port (
                A, B : in bit; -- inputs
                F    : out bit; -- output
                S    : in bit_vector(2 downto 0); -- op selection
                Ci   : in bit; -- carry in
                Co   : out bit -- carry out
            );
        end component;

        signal carry: bit_vector (size-1 downto 0);
        signal bitResult: bit_vector (size-1 downto 0);
        signal subtracao: bit;

    begin
        subtracao <= '1' when S = "100" else '0';

        gen: for i in size-1 downto 0 generate
            lsb: if i = 0 generate
                boi: bitOperation port map (A => A(i), B => B(i), F => bitResult(i), S => S, Ci => subtracao, Co => carry(i));
            end generate lsb;
            msb: if i > 0 generate
                boi: bitOperation port map (A => A(i), B => B(i), F => bitResult(i), S => S, Ci => carry(i-1), Co => carry(i));
            end generate msb;
        end generate gen;

        genflip: for i in size-1 downto 0 generate
            F(i) <= bitResult(size-1-i) when S = "110" else bitResult(i);
        end generate genflip;

        Z <= '1' when unsigned(bitResult) = 0 else '0';

        Ov <= carry(size-1) xor carry(size-2) when S = "001" else
            carry(size-1) xor carry(size-2) when S = "100" else
            '0';

        Co <= carry(size-1) when S = "001" else
            carry(size-1) when S = "100" else
            '0';

    end architecture combinatory;

--------------------------------------------------------------------------------

    library ieee;
    use ieee.numeric_bit.all;

    entity data_flow is
        generic (
            addr_s : natural := 16;
            word_s : natural := 32 
        );
        port (
            clock, reset: in  bit;
            -- Memory Interface
            memA_addr, memB_addr  : out bit_vector (addr_s - 1 downto 0);
            memB_wrd              : out bit_vector (word_s - 1 downto 0);
            memA_rdd, memB_rdd    : in  bit_vector (word_s - 1 downto 0);
            -- Control Unit Interface
            pc_en, ir_en, sp_en            : in  bit;
            pc_src, mem_a_addr_src,
            mem_b_mem_src                  : in  bit;
            mem_b_addr_src, mem_b_wrd_src,
            alu_a_src, alu_b_src           : in  bit_vector (1 downto 0);
            alu_shfimm_src, alu_mem_src    : in  bit;
            alu_op                         : in  bit_vector (2 downto 0);
            instruction                    : out bit_vector (7 downto 0)
        );
    end entity data_flow;

    architecture behavorial of data_flow is
        component d_register is
            generic (
                width       : natural;
                reset_value : natural
            );
            port (
                clock, reset, load : in bit;
                d : in  bit_vector(width - 1 downto 0);
                q : out bit_vector(width - 1 downto 0)
            );
        end component d_register;

        component alu is
            generic (
                size : natural
            );
            port (
                A, B : in bit_vector(size-1 downto 0);
                F    : out bit_vector(size-1 downto 0);
                S    : in bit_vector(2 downto 0);
                Z    : out bit;
                Ov   : out bit;
                Co   : out bit 
            );
        end component alu;

        -- --Signal registers
            signal pc_in  : bit_vector (addr_s - 1 downto 0);
            signal pc_out : bit_vector (addr_s - 1 downto 0);
            signal sp_out : bit_vector (word_s - 1 downto 0);
            signal ir_out : bit_vector (7 downto 0);

        -- -- Signal ULA
            signal zero     : bit;
            signal overflow : bit;
            signal carry    : bit;
            signal alu_a    : bit_vector (word_s - 1 downto 0);
            signal alu_b    : bit_vector (word_s - 1 downto 0);
            signal alu_out  : bit_vector (word_s - 1 downto 0);
        --     --alu_op ja existe (No entity data_flow)

        -- -- Signal Data flow
            signal memb_mem : bit_vector (word_s - 1 downto 0);
            signal imm_shft : bit_vector (word_s - 1 downto 0);
            signal alu_mem  : bit_vector (word_s - 1 downto 0);

        function resize(x: bit_vector; size_auxiliar: natural) return bit_vector is
            variable y : bit_vector(size_auxiliar-1 downto 0);
        begin
            y := bit_vector(to_unsigned(0, size_auxiliar));
            y(x'length - 1 downto 0) := x;
            return y;
        end function resize;

    begin
        PC: d_register
            generic map (
                width       => addr_s,
                reset_value => 0
            )
            port map (
                clock => clock,
                reset => reset,
                load  => pc_en,
                d     => pc_in,
                q     => pc_out
            );
        
        SP: d_register  
            generic map (
                width       => word_s,
                reset_value => 16#1FFF8# -- Duas operações de 4 Bytes são necessárias para que o SP seja inicializado com o valor correto
            )
            port map (
                clock => clock,
                reset => reset,
                load  => sp_en,
                d     => alu_out,
                q     => sp_out
            );

        IR: d_register
            generic map (
                width       => 8,      -- sempre 1 byte, 8 bits
                reset_value => 0
            )
            port map (
                clock => clock,
                reset => reset,
                load  => ir_en,
                d     => memA_rdd(7 downto 0),
                q     => ir_out
            );

        ULA: alu
            generic map (
                size => word_s
            )
            port map (
                A => alu_a,
                B => alu_b,
                F => alu_out,
                S => alu_op,
                Z => zero,
                Ov => overflow,
                Co => carry
            );

        

        pc_in     <= alu_out(addr_s-1 downto 0)  when pc_src = '0' else 
                    memA_rdd(addr_s-1 downto 0) when pc_src = '1';

        memA_addr <= sp_out(addr_s-1 downto 0) when mem_a_addr_src = '0' else
                     pc_out                    when mem_a_addr_src = '1';

        memB_addr <= sp_out(addr_s-1 downto 0)   when mem_b_addr_src = "00" else
                    memA_rdd(addr_s-1 downto 0) when mem_b_addr_src = "01" else
                    alu_out(addr_s-1 downto 0)  when mem_b_addr_src = "10" else
                    alu_out(addr_s-1 downto 0)  when mem_b_addr_src = "11";

        memB_wrd  <= alu_out  when mem_b_wrd_src = "00" else
                    memb_mem when mem_b_wrd_src = "01" else
                    sp_out   when mem_b_wrd_src = "10" else
                    resize(ir_out(6 downto 0), word_s) when mem_b_wrd_src = "11";

        memb_mem  <= memA_rdd when mem_b_mem_src = '0' else
                    memB_rdd when mem_b_mem_src = '1';

        alu_a     <= resize(pc_out, word_s) when alu_a_src = "00" else
                    sp_out   when alu_a_src = "01" else
                    memA_rdd when alu_a_src = "10" else
                    memA_rdd when alu_a_src = "11";                               

        alu_b     <= imm_shft when alu_b_src = "00" else
                    alu_mem  when alu_b_src = "01" else
                    resize(ir_out(4 downto 0) & "00000",word_s) when alu_b_src = "10" else
                    resize(not(ir_out(4)) & ir_out(3 downto 0) & "00", word_s) when alu_b_src = "11";
    
        imm_shft  <= bit_vector(to_unsigned(1, word_s)) when alu_shfimm_src = '0' else
                    bit_vector(to_unsigned(4, word_s)) when alu_shfimm_src = '1';

        alu_mem   <= bit_vector(memA_rdd(word_s - 8 downto 0) & ir_out(6 downto 0)) when alu_mem_src = '0' else
                    memB_rdd when alu_mem_src = '1';
        
        instruction <= ir_out;

    end architecture behavorial;

--------------------------------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity control_unit is
    port (
        clock, reset : in bit;
        pc_en, ir_en, sp_en,
        pc_src, mem_a_addr_src, mem_b_mem_src, alu_shfimm_src, alu_mem_src,
        mem_we, mem_enable: out bit;
        mem_b_addr_src, mem_b_wrd_src, alu_a_src, alu_b_src: out bit_vector(1 downto 0);
        alu_op: out bit_vector(2 downto 0);
        busy: in bit;
        instruction: in bit_vector(7 downto 0);
        halted: out bit
    );
end entity control_unit;

architecture behavior of control_unit is

    type state_type is (
        fetch,
        decode,
        execute
        );

    type op_code is (
        BREAK,
        PUSHSP,
        POPPC,
        ADD,
        B_AND,
        B_OR,
        LOAD,
        B_NOT,
        FLIP,
        NOP,
        STORE,
        POPSP,
        ADDSP,
        CALL,
        STORESP,
        LOADSP,
        IM1,
        IMN
    );


    type second_op is (
        mem_add,
        mem_and,
        mem_or,
        none
    );

    signal second_op_sel : second_op := none;
    signal op_code_sel : op_code;

    signal halt : bit := '0';
    signal waited_mem: bit := '0';
    signal wait_mem: bit := '0';

    signal current_state, next_state : state_type;


begin

    sincrono: process(clock, reset)
    begin
        if (reset='1' and rising_edge(clock)) then
            current_state <= fetch;
        elsif (rising_edge(clock) and halt = '0') then
            current_state <= next_state;
        end if;
    end process sincrono;


    combinatorio: process(current_state, busy)
    begin
        if wait_mem = '1' then
            sp_en <= '0';
            pc_en <= '0';
            mem_we <= '0';
            if busy = '0' then
                mem_enable <= '0';
            end if;
        end if;
        case(current_state) is
            when fetch =>
                if wait_mem = '0' then
                    -- Enables
                    sp_en <= '0';
                    ir_en <= '1';
                    pc_en <= '0';
                    mem_enable <= '1';
                    
                    -- Pc = Pc + 1
                    alu_op <= "001"; -- soma
                    alu_a_src <= "00"; -- PC
                    alu_b_src <= "00"; -- imm_shft
                    alu_shfimm_src <= '0'; -- imm_shft = 1

                    mem_a_addr_src <= '1'; -- mem_addr = Pc, colocar valor de mem[pc][7:0] em IR
                    -- Não há necessidade de mudar o endereço de memória de B
                    wait_mem <= '1';
                elsif falling_edge(busy) then
                    pc_en <= '1';
                    ir_en <= '0';
                    wait_mem <= '0';
                    next_state <= decode;
                end if;
            when decode =>
                pc_en <= '0';
                next_state <= execute;
                
                if instruction = "00000000" then
                    op_code_sel <= BREAK;
                elsif instruction = "00000010" then
                    op_code_sel <= PUSHSP;
                elsif instruction = "00000100" then
                    op_code_sel <= POPPC;
                elsif instruction = "00000101" then
                    op_code_sel <= ADD;
                elsif instruction = "00000110" then
                    op_code_sel <= B_AND;
                elsif instruction = "00000111" then
                    op_code_sel <= B_OR;
                elsif instruction = "00001000" then
                    op_code_sel <= LOAD;
                elsif instruction = "00001001" then
                    op_code_sel <= B_NOT;
                elsif instruction = "00001010" then
                    op_code_sel <= FLIP;
                elsif instruction = "00001011" then
                    op_code_sel <= NOP;
                elsif instruction = "00001100" then
                    op_code_sel <= STORE;
                elsif instruction = "00001101" then
                    op_code_sel <= POPSP;
                elsif instruction(7 downto 4) = "0001" then
                    op_code_sel <= ADDSP;
                elsif instruction(7 downto 3) = "001" then
                    op_code_sel <= CALL;
                elsif instruction(7 downto 3) = "010" then
                    op_code_sel <= STORESP;
                elsif instruction(7 downto 3) = "011" then
                    op_code_sel <= LOADSP;
                elsif instruction(7) = '1' then
                    if op_code_sel = IM1 then
                        op_code_sel <= IMN;
                    else
                        op_code_sel <= IM1;
                    end if;
                end if;
            when execute =>
                case op_code_sel is
                    when BREAK =>
                        sp_en <= '0';
                        pc_en <= '0';
                        ir_en <= '0';
                        mem_we <= '0';
                        halted <= '1';
                        halt <= '1';
                    when PUSHSP =>
                        if wait_mem = '0' then
                            mem_enable <= '1';
                            sp_en <= '1';

                            ---- SP = SP - 4
                            alu_a_src <= "01";      -- Saida do registador SP 
                            -- alu_a = SP
                            alu_b_src <= "00";      -- Saida de shfimm
                            -- alu_b = imm_shft
                            alu_shfimm_src <= '1';  
                            -- imm_shft = 4
                            alu_op <= "100";
                            -- alu_F = alu_a - alu_b = sp - 4
                            ---- SP = SP - 4
                        
                            -- mem[sp-4]=sp
                            mem_we <= '1';          -- escreve na memoria no addr_B
                            mem_b_wrd_src <= "10";  -- Saida de SP
                            -- mem_B_wrd = SP
                            mem_b_addr_src <= "10"; -- Saida da ULA
                            -- mem_B_addr = alu_F = SP - 4
                            wait_mem <= '1';
                        elsif falling_edge(busy) then
                            next_state <= fetch;
                            wait_mem <= '0';
                        end if;
                    when POPPC =>
                        if wait_mem = '0' then
                            mem_enable <= '1';
                            sp_en <= '1';

                            ---- SP = SP + 4
                            alu_a_src <= "01";      -- Saida do registador SP 
                            alu_b_src <= "00";      -- Saida de shfimm
                            alu_shfimm_src <= '1';  
                            alu_op <= "001";
                            ---- SP = SP + 4; alu_f = sp + 4

                            mem_a_addr_src <= '0';
                            wait_mem <= '1';
                        elsif falling_edge(busy) then
                            wait_mem <= '0';
                            pc_en <= '1';
                            pc_src <= '1';
                            next_state <= fetch;
                        end if;
                    when ADD =>
                        if wait_mem = '0' then
                            mem_enable <= '1';
                            sp_en <= '1';

                            ---- SP = SP + 4
                            alu_a_src <= "01";      -- Saida do registador SP 
                            alu_b_src <= "00";      -- Saida de shfimm
                            alu_shfimm_src <= '1';  
                            alu_op <= "001";
                            ---- SP = SP + 4; alu_f = sp + 4

                            mem_a_addr_src <= '0';   -- a_addr = sp 
                            mem_b_addr_src <= "10";  -- b_addr = sp + 4
                            wait_mem <= '1';
                        elsif waited_mem = '0' and falling_edge(busy) then
                            waited_mem <= '1';

                            mem_b_addr_src <= "00";
                            mem_b_wrd_src <= "00";

                            alu_a_src <= "10";
                            alu_b_src <= "01";
                            alu_mem_src <= '1';
                            alu_op <= "001";

                            mem_enable <= '1';
                            mem_we <= '1';
                            
                        elsif waited_mem = '1' and falling_edge(busy) then
                            waited_mem <= '0';
                            wait_mem <= '0';
                            next_state <= fetch;
                        end if;
                    when B_AND =>
                        if wait_mem = '0' then
                            mem_enable <= '1';
                            sp_en <= '1';

                            ---- SP = SP + 4
                            alu_a_src <= "01";      -- Saida do registador SP 
                            alu_b_src <= "00";      -- Saida de shfimm
                            alu_shfimm_src <= '1';  
                            alu_op <= "001";
                            ---- SP = SP + 4; alu_f = sp + 4

                            mem_a_addr_src <= '0';   -- a_addr = sp 
                            mem_b_addr_src <= "10";  -- b_addr = sp + 4
                            wait_mem <= '1';
                            
                        elsif waited_mem = '0' and falling_edge(busy) then
                            waited_mem <= '1';

                            mem_b_addr_src <= "00";
                            mem_b_wrd_src <= "00";

                            alu_a_src <= "10";
                            alu_b_src <= "01";
                            alu_mem_src <= '1';
                            alu_op <= "010";

                            mem_enable <= '1';
                            mem_we <= '1';
                            
                        elsif waited_mem = '1' and falling_edge(busy) then
                            waited_mem <= '0';
                            wait_mem <= '0';
                            next_state <= fetch;
                        end if;
                    when B_OR =>
                        if wait_mem = '0' then
                            mem_enable <= '1';
                            sp_en <= '1';

                            ---- SP = SP + 4
                            alu_a_src <= "01";      -- Saida do registador SP 
                            alu_b_src <= "00";      -- Saida de shfimm
                            alu_shfimm_src <= '1';  
                            alu_op <= "001";
                            ---- SP = SP + 4; alu_f = sp + 4

                            mem_a_addr_src <= '0';   -- a_addr = sp 
                            mem_b_addr_src <= "10";  -- b_addr = sp + 4
                            wait_mem <= '1';
                        elsif waited_mem = '0' and falling_edge(busy) then
                            waited_mem <= '1';

                            mem_b_addr_src <= "00";
                            mem_b_wrd_src <= "00";

                            alu_a_src <= "10";
                            alu_b_src <= "01";
                            alu_mem_src <= '1';
                            alu_op <= "011";

                            mem_enable <= '1';
                            mem_we <= '1';
                        elsif waited_mem = '1' and falling_edge(busy) then
                            waited_mem <= '0';
                            wait_mem <= '0';
                            next_state <= fetch;
                        end if;
                    when LOAD =>
                        if wait_mem = '0' then
                            mem_enable <= '1';
                            mem_a_addr_src <= '0';   -- a_addr = sp 
                            mem_b_addr_src <= "00";  -- b_addr = sp
                            wait_mem <= '1';
                        elsif waited_mem = '0' and falling_edge(busy) then
                            waited_mem <= '1';
                            mem_b_addr_src <= "00";
                            mem_b_wrd_src <= "00";
                            alu_a_src <= "10";
                            alu_op <= "000";
                            mem_enable <= '1';
                            mem_we <= '1';
                        elsif waited_mem = '1' and falling_edge(busy) then
                            waited_mem <= '0';
                            wait_mem <= '0';
                            next_state <= fetch;
                        end if;
                    when B_NOT =>
                        if wait_mem = '0' then
                            mem_enable <= '1';
                            sp_en <= '1';

                            ---- SP = SP + 4
                            alu_a_src <= "01";      -- Saida do registador SP 
                            alu_b_src <= "00";      -- Saida de shfimm
                            alu_shfimm_src <= '1';  
                            alu_op <= "001";
                            ---- SP = SP + 4; alu_f = sp + 4

                            mem_a_addr_src <= '0';   -- a_addr = sp 
                            mem_b_addr_src <= "10";  -- b_addr = sp + 4
                            wait_mem <= '1';
                        elsif waited_mem = '0' and falling_edge(busy) then
                            waited_mem <= '1';

                            mem_b_addr_src <= "00";
                            mem_b_wrd_src <= "00";

                            alu_a_src <= "10";
                            alu_b_src <= "01";
                            alu_mem_src <= '1';
                            alu_op <= "101";

                            mem_enable <= '1';
                            mem_we <= '1';
                        elsif waited_mem = '1' and falling_edge(busy) then
                            waited_mem <= '0';
                            wait_mem <= '0';
                            next_state <= fetch;
                        end if;
                    when FLIP =>
                        if wait_mem = '0' then
                            mem_enable <= '1';
                            sp_en <= '1';

                            ---- SP = SP + 4
                            alu_a_src <= "01";      -- Saida do registador SP 
                            alu_b_src <= "00";      -- Saida de shfimm
                            alu_shfimm_src <= '1';  
                            alu_op <= "001";
                            ---- SP = SP + 4; alu_f = sp + 4

                            mem_a_addr_src <= '0';   -- a_addr = sp 
                            mem_b_addr_src <= "10";  -- b_addr = sp + 4
                            wait_mem <= '1';
                        elsif waited_mem = '0' and falling_edge(busy) then
                            waited_mem <= '1';

                            mem_b_addr_src <= "00";
                            mem_b_wrd_src <= "00";

                            alu_a_src <= "10";
                            alu_b_src <= "01";
                            alu_mem_src <= '1';
                            alu_op <= "110";

                            mem_enable <= '1';
                            mem_we <= '1';
                            
                        elsif waited_mem = '1' and falling_edge(busy) then
                            waited_mem <= '0';
                            wait_mem <= '0';
                            next_state <= fetch;
                        end if;
                    when NOP =>
                        next_state <= fetch;
                        -- Faz nada
                    when STORE =>
                        if wait_mem = '0' then
                            mem_enable <= '1';
                            sp_en <= '1';

                            ---- SP = SP + 4
                            alu_a_src <= "01";      -- Saida do registador SP 
                            alu_b_src <= "00";      -- Saida de shfimm
                            alu_shfimm_src <= '1';  
                            alu_op <= "001";
                            ---- SP = SP + 4; alu_f = sp + 4

                            mem_a_addr_src <= '0';   -- a_addr = sp 
                            mem_b_addr_src <= "10";  -- b_addr = sp + 4
                            wait_mem <= '1';
                        elsif waited_mem = '0' and falling_edge(busy) then
                            waited_mem <= '1';
                            mem_b_addr_src <= "00";
                            mem_b_wrd_src <= "01";
                            mem_b_mem_src <= '1';
                            alu_a_src <= "10";
                            alu_op <= "000";
                            mem_enable <= '1';
                            mem_we <= '1';
                            wait_mem <= '1';
                        elsif waited_mem = '1' and falling_edge(busy) then
                            waited_mem <= '0';
                            wait_mem <= '0';
                            next_state <= fetch;
                        end if;
                    when POPSP =>
                        if wait_mem = '0' then
                            mem_enable <= '1';
                            mem_a_addr_src <= '0';
                            wait_mem <= '1';
                        elsif falling_edge(busy) then
                            wait_mem <= '0';
                            sp_en <= '1';
                            alu_a_src <= "10";
                            alu_op <= "000";
                            next_state <= fetch;
                        end if;
                    when ADDSP =>
                        if wait_mem = '0' then
                            mem_enable <= '1';

                            alu_a_src <= "01";      -- Saida do registador SP 
                            alu_b_src <= "11";      -- Saida de shfimm 
                            alu_op <= "001";

                            mem_b_addr_src <= "10";
                            mem_a_addr_Src <= '0';

                            wait_mem <= '1';
                        elsif waited_mem = '0' and falling_edge(busy) then
                            waited_mem <= '1';

                            alu_a_src <= "10";
                            alu_b_src <= "01";
                            alu_mem_src <= '1';

                            mem_b_wrd_src <= "00";
                            mem_b_addr_src <= "00";
                            mem_enable <= '1';
                            mem_we <= '1';
                        elsif waited_mem = '1' and falling_edge(busy) then
                            wait_mem <= '0';
                            waited_mem <= '0';
                            next_state <= fetch;
                        end if;
                        
                    when CALL =>
                        if wait_mem = '0' then
                            wait_mem <= '1';

                            sp_en <= '1';
                            alu_a_src <= "01";
                            alu_b_src <= "00";
                            alu_shfimm_src <= '1';
                            alu_op <= "000";

                            mem_enable <= '1';
                        elsif waited_mem = '0' and falling_edge(busy) then
                            wait_mem <= '0';
                            waited_mem <= '1';

                            mem_we <= '1';
                            mem_enable <= '1';

                            mem_b_wrd_src <= "00";
                            alu_a_src <= "00";
                            alu_op <= "000";

                            mem_b_addr_src <= "00";
                        elsif waited_mem = '1' and falling_edge(busy) then
                            wait_mem <= '0';
                            waited_mem <= '0';

                            pc_en <= '1';
                            pc_src <= '0';
                            
                            alu_b_src <= "10";
                            alu_op <= "111";

                            next_state <= fetch;
                        end if;
                    when STORESP =>
                        if wait_mem = '0' then
                            wait_mem <= '1';

                            mem_a_addr_src <= '0';
                            mem_enable <= '1';
                            
                        elsif waited_mem = '0' and falling_edge(busy) then
                            waited_mem <= '1';

                            mem_b_wrd_src <= "01";
                            mem_b_mem_src <= '0';

                            mem_b_addr_src <= "10";

                            alu_a_src <= "01";
                            alu_b_src <= "11";
                            alu_op <= "001";

                            mem_enable <= '1';
                            mem_we <= '1';

                        elsif waited_mem = '1' and falling_edge(busy) then
                            sp_en <= '1';

                            alu_a_src <= "01";
                            alu_b_src <= "00";
                            alu_shfimm_src <= '1';
                            alu_op <= "001";

                            wait_mem <= '0';
                            waited_mem <= '0';
                            next_state <= fetch;
                        end if;
                    when LOADSP =>
                        if wait_mem = '0' then
                            wait_mem <= '1';

                            alu_a_src <= "01";
                            alu_b_src <= "11";
                            alu_op <= "001";

                            mem_b_addr_src <= "10";
                            mem_enable <= '1';
                            
                        elsif waited_mem = '0' and falling_edge(busy) then
                            waited_mem <= '1';

                            sp_en <= '1';

                            mem_b_wrd_src <= "01";
                            mem_b_mem_src <= '1';

                            mem_b_addr_src <= "10";

                            alu_a_src <= "01";
                            alu_b_src <= "00";
                            alu_shfimm_src <= '1';
                            alu_op <= "100";

                            mem_enable <= '1';
                            mem_we <= '1';

                        elsif waited_mem = '1' and falling_edge(busy) then
                            wait_mem <= '0';
                            waited_mem <= '0';
                            next_state <= fetch;
                        end if;
                    when IM1 =>
                        if wait_mem = '0' then
                            sp_en <= '1';

                            alu_a_src <= "01";
                            alu_b_src <= "00";
                            alu_shfimm_src <= '1';
                            alu_op <= "100";

                            mem_b_wrd_src <= "11";
                            mem_b_addr_src <= "00";

                            mem_enable <= '1';
                            mem_we <= '1';
                        elsif falling_edge(busy) then
                            wait_mem <= '0';
                            next_state <= fetch;
                        end if;
                    when IMN =>
                        if wait_mem = '0' then
                            mem_b_addr_src <= "00";
                            mem_a_addr_src <= '0';

                            mem_enable <= '1';
                            wait_mem <= '0';
                        elsif waited_mem = '0' and falling_edge(busy) then
                            waited_mem <= '1';

                            mem_b_addr_src <= "00";
                            mem_b_wrd_src <= "00";

                            alu_b_src <= "01";
                            alu_op <= "111";
                            alu_mem_src <= '0';

                            mem_enable <= '1';
                            mem_we <= '1';
                        elsif waited_mem = '1' and falling_edge(busy) then
                            waited_mem <= '0';
                            wait_mem <= '0';
                            next_state <= fetch;
                        end if;
                    when others =>
                        sp_en <= '0';
                        pc_en <= '0';
                        ir_en <= '0';
                        mem_we <= '0';
                        halted <= '1';
                        halt <= '1';
                        op_code_sel <= break;
                end case;
            when others =>
                --Nada
        end case;
    end process combinatorio;
end architecture behavior;

--------------------------------------------------------------------------------

library ieee;
use ieee.numeric_bit.all;

entity polistack is
    generic (
        addr_s : natural := 16; -- address size in bits
        word_s : natural := 32 -- word size in bits
    );
    port (
        clock, reset: in bit;
        halted: out bit;
        --memory interface
        mem_we, mem_enable : out bit;
        memA_addr, memB_addr : out bit_vector(addr_s-1 downto 0);
                   memB_wrd  : out bit_vector(word_s-1 downto 0);
        memA_rdd,  memB_rdd  : in  bit_vector(word_s-1 downto 0);
        busy: in bit
    );
end entity polistack;

architecture allinone of polistack is

    component control_unit is
        port (
            clock, reset : in bit;
            pc_en, ir_en, sp_en,
            pc_src, mem_a_addr_src, mem_b_mem_src, alu_shfimm_src, alu_mem_src,
            mem_we, mem_enable: out bit;
            mem_b_addr_src, mem_b_wrd_src, alu_a_src, alu_b_src: out bit_vector(1 downto 0);
            alu_op: out bit_vector(2 downto 0);
            busy: in bit;
            instruction: in bit_vector(7 downto 0);
            halted: out bit
        );
    end component control_unit;

    component data_flow is
        generic (
            addr_s : natural;
            word_s : natural 
        );
        port (
            clock, reset: in  bit;
            -- Memory Interface
            memA_addr, memB_addr : out bit_vector (addr_s - 1 downto 0);
                       memB_wrd  : out bit_vector (word_s - 1 downto 0);
            memA_rdd,  memB_rdd  : in  bit_vector (word_s - 1 downto 0);
            -- Control Unit Interface
            pc_en, ir_en, sp_en            : in  bit;
            pc_src, mem_a_addr_src,
            mem_b_mem_src                  : in  bit;
            mem_b_addr_src, mem_b_wrd_src,
            alu_a_src, alu_b_src           : in  bit_vector (1 downto 0);
            alu_shfimm_src, alu_mem_src    : in  bit;
            alu_op                         : in  bit_vector (2 downto 0);
            instruction                    : out bit_vector (7 downto 0)
        );
    end component data_flow;

    
    -- Signal beetween control unit and data flow
    signal pc_en_sig, ir_en_sig, sp_en_sig : bit;
    signal pc_src_sig, mem_a_addr_src_sig, mem_b_mem_src_sig : bit;
    signal alu_shfimm_src_sig, alu_mem_src_sig: bit;
    signal mem_b_addr_src_sig, mem_b_wrd_src_sig, alu_a_src_sig, alu_b_src_sig: bit_vector(1 downto 0);
    signal alu_op_sig: bit_vector(2 downto 0);
    signal instruction_sig: bit_vector(7 downto 0);


begin

    CU: control_unit
        port map (
            clock, reset,
            pc_en => pc_en_sig,
            ir_en => ir_en_sig,
            sp_en => sp_en_sig,
            pc_src => pc_src_sig,
            mem_a_addr_src => mem_a_addr_src_sig,
            mem_b_mem_src => mem_b_mem_src_sig,
            alu_shfimm_src => alu_shfimm_src_sig,
            alu_mem_src => alu_mem_src_sig,
            mem_we => mem_we,
            mem_enable => mem_enable,
            mem_b_addr_src => mem_b_addr_src_sig,
            mem_b_wrd_src => mem_b_wrd_src_sig,
            alu_a_src => alu_a_src_sig,
            alu_b_src => alu_b_src_sig,
            alu_op => alu_op_sig,
            busy => busy,
            instruction => instruction_sig,
            halted => halted
        );

    DF: data_flow
        generic map (
            addr_s => addr_s,
            word_s => word_s
        )
        port map (
            clock => clock,
            reset => reset,
            memA_addr => memA_addr,
            memB_addr => memB_addr,
            memB_wrd => memB_wrd,
            memA_rdd => memA_rdd,
            memB_rdd => memB_rdd,
            pc_en => pc_en_sig,
            ir_en => ir_en_sig,
            sp_en => sp_en_sig,
            pc_src => pc_src_sig,
            mem_a_addr_src => mem_a_addr_src_sig,
            mem_b_mem_src => mem_b_mem_src_sig,
            alu_shfimm_src => alu_shfimm_src_sig,
            alu_mem_src => alu_mem_src_sig,
            mem_b_addr_src => mem_b_addr_src_sig,
            mem_b_wrd_src => mem_b_wrd_src_sig,
            alu_a_src => alu_a_src_sig,
            alu_b_src => alu_b_src_sig,
            alu_op => alu_op_sig,
            instruction => instruction_sig
        );
    
end architecture allinone;

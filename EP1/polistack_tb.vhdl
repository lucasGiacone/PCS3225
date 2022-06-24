library ieee;
use ieee.numeric_bit.all;
use std.textio.all;

entity polistack_tb is
end entity polistack_tb;

architecture test of polistack_tb is
    component polistack is
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
    end component polistack;


    signal clock : bit := '0';
    signal finished : bit := '0';
    constant half_period : time := 5 ns;

    constant addr_s : natural := 16;
    constant word_s : natural := 32;

    signal reset: bit := '0';
    signal halted: bit;
    signal busy: bit  := '0';
    signal mem_we: bit;
    signal mem_enable: bit;

    signal memA_addr, memB_addr : bit_vector (addr_s - 1 downto 0);
    signal memB_wrd : bit_vector (word_s - 1 downto 0);
    signal memA_rdd, memB_rdd : bit_vector (word_s - 1 downto 0);

begin
    PS : polistack
        generic map (
            addr_s => addr_s,
            word_s => word_s
        )
        port map (
            clock => clock,
            reset => reset,
            mem_we => mem_we,
            mem_enable => mem_enable,
            memA_addr => memA_addr,
            memB_addr => memB_addr,
            memB_wrd => memB_wrd,
            memA_rdd => memA_rdd,
            memB_rdd => memB_rdd,
            halted => halted,
            busy => busy
        );

    clock <= not clock after half_period when finished /= '1' else '0';

    process begin
        -- Reset para os registradores assumirem valores iniciais
        reset <= '1';
        wait until clock = '1';
        reset <= '0';
        assert memA_addr = bit_vector(to_unsigned(0, addr_s)) report "memoria no endereço errado obtido" & integer'image(to_integer(unsigned(memA_addr))) severity failure;
        assert memB_addr = bit_vector(to_unsigned(16#fff8#, addr_s)) report "memoria no endereço errado obtido" & integer'image(to_integer(unsigned(memB_addr))) severity failure;
        memA_rdd <= bit_vector(to_unsigned(16#000b820b#, word_S)); -- 0x000b0b0b
        memB_rdd <= bit_vector(to_unsigned(0, word_S));
        busy <= '1';
        wait until clock = '1';
        wait until clock = '1';
        busy <= '0';
        wait until clock = '1';
        wait until clock = '1';
        wait until clock = '1';
        memA_rdd <= bit_vector(to_unsigned(16#00000b82#, word_S)); -- 0x000b0b0b
        memB_rdd <= bit_vector(to_unsigned(0, word_S));
        busy <= '1';
        wait until clock = '1';
        wait until clock = '1';
        busy <= '0';
        wait until clock = '1';
        wait until clock = '1';
        wait until clock = '1';
        wait until clock = '1';
        wait until clock = '1';
        wait until clock = '1';
        wait until clock = '1';
        wait until clock = '1';
        wait until clock = '1';
        wait until clock = '1';
        wait until clock = '1';
        wait until clock = '1';
        wait until clock = '1';
        wait until clock = '1';
        wait until clock = '1';
        wait until clock = '1';
        wait until clock = '1';
        finished <= '1'; -- Finaliza o clock para dar halt e o arquivo vcd nao ficar gigantesco...
    end process;
end architecture test;



-- -- Isso simula uma operação PUSHSP
                -- mem_b_wrd_src <= "10";
                -- mem_b_addr_src <= "10";
                -- alu_a_src <= "01";
                -- alu_b_src <= "00";
                -- alu_shfimm_src <= '1';
                -- sp_en <= '1';
                -- alu_op <= "100";
                -- ir_en <= '0';
                -- pc_en <= '0';
                -- mem_a_addr_src <= '0'; -- Pode ser qualquer valor
                -- pc_src <= '0'; -- Pode ser qualquer valor
                -- memA_rdd <= X"00000000"; -- Pode ser qualquer valor
                -- memB_rdd <= X"10000000"; -- Pode ser qualquer valor
                -- mem_b_mem_src <= '0'; -- Pode ser qualquer valor
                -- alu_mem_src <= '0'; -- Pode ser qualquer valor
                -- wait for 1 ns;
                -- -- Repete a operação PUSHSP 4 vezes
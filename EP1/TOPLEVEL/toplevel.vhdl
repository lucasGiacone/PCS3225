library ieee;
use ieee.numeric_bit.all;

entity toplevel is end;

architecture allinone of toplevel is
    component polistack is
        generic (
            addr_s : natural; -- address size in bits
            word_s : natural -- word size in bits
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

    component dpram is
        generic(
            addr_size : natural
        );
        port 
        (	
            data_b	: in bit_vector(31 downto 0);
            addr_a	: in bit_vector(addr_size - 1 downto 0);
            addr_b	: in bit_vector(addr_size - 1 downto 0);
            we	    : in bit;
            clock	: in bit;
            enable  : in bit;
            q_a		: out bit_vector(31 downto 0);
            q_b		: out bit_vector(31 downto 0);
            bsy     : out bit
        );
    end component dpram;

    signal clock  : bit := '0';
    signal reset  : bit := '1';
    signal busy   : bit;
    signal halted : bit;

    signal mem_we : bit;
    signal mem_enable : bit;
    signal a_rdd : bit_vector(31 downto 0);
    signal b_rdd : bit_vector(31 downto 0);
    signal a_addr: bit_vector(16 downto 0);
    signal b_addr: bit_vector(16 downto 0);
    signal b_wrd : bit_vector(31 downto 0);

    constant half_period : time := 1 ns;

begin
    clock <= not clock after half_period when halted /= '1' else '0';
    reset <= '0' after half_period;

    proc : polistack
        generic map (
            addr_s => 17,
            word_s => 32
        )
        port map (
            clock => clock,
            reset => reset,
            mem_we => mem_we,
            mem_enable => mem_enable,
            memA_addr => a_addr,
            memB_addr => b_addr,
            memB_wrd => b_wrd,
            memA_rdd => a_rdd,
            memB_rdd => b_rdd,
            halted => halted,
            busy => busy
        );

    mem: dpram
        generic map(
            addr_size => 17
        )
        port map(
            data_b => b_wrd,
            addr_a => a_addr,
            addr_b => b_addr,
            we => mem_we,
            clock => clock,
            enable => mem_enable,
            q_a => a_rdd,
            q_b => b_rdd,
            bsy => busy
        );


end;
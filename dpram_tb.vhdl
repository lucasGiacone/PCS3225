library ieee;
use ieee.numeric_bit.all;

entity dpram_tb is end;

architecture test of dpram_tb is
    component dpram is
        generic(
            addr_size : natural := 17
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

    signal clock : bit := '0';
    signal finished : bit := '0';
    constant half_period : time := 5 ns;


    signal mem_enable : bit := '0';
    signal mem_we     : bit := '0';
    signal mem_a_rdd  : bit_vector(31 downto 0);
    signal mem_b_rdd  : bit_vector(31 downto 0);
    signal mem_a_addr : bit_vector(16 downto 0);
    signal mem_b_addr : bit_vector(16 downto 0);
    signal mem_b_wrd  : bit_vector(31 downto 0);
    signal busy       : bit;

begin
    
    clock <= not clock after half_period when finished /= '1' else '0';

    ram: dpram
    generic map(
        addr_size => 17
    )
    port map(
        data_b => mem_b_wrd,
        addr_a => mem_a_addr,
        addr_b => mem_b_addr,
        we => mem_we,
        clock => clock,
        enable => mem_enable,
        q_a => mem_a_rdd,
        q_b => mem_b_rdd,
        bsy => busy
    );

    process begin
        wait until clock = '1';
        mem_enable <= '1';
        wait until busy = '0';
        mem_enable <= '0';
        wait until clock = '1';
        wait until clock = '1';
        mem_enable <= '1';
        wait until clock = '1';
        wait until clock = '1';
        wait until clock = '1';
        finished <= '1';
    end process;
    
end;
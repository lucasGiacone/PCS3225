library ieee;
use ieee.numeric_bit.all;
use std.textio.all;

entity dpram is
    generic(
        addr_size : natural := 17
    );
	port 
	(	
		data_b	: in bit_vector(31 downto 0);
		addr_a	: in bit_vector(addr_size - 1 downto 0);
		addr_b	: in bit_vector(addr_size - 1 downto 0);
		we	    : in bit := '0';
		clock	: in bit;
        enable  : in bit;
		q_a		: out bit_vector(31 downto 0);
		q_b		: out bit_vector(31 downto 0);
        bsy     : out bit
	);
end entity dpram;

architecture rtl of dpram is
	constant depth : natural := 2**addr_size;
	subtype word_t is bit_vector(7 downto 0);
	type memory_t is array(0 to depth-1) of word_t;
    signal done : bit := '0';
    signal busy : bit;

    impure function initialize(arq_name: in string) return memory_t is
        file     arq  : text open read_mode is arq_name;
        variable line    : line;
        variable temp_bv  : bit_vector(7 downto 0);
        variable temp_mem : memory_t;
        begin
        for i in memory_t'range loop
            readline(arq, line);
            read(line, temp_bv);
            temp_mem(i) := temp_bv;
        end loop;
        return temp_mem;
    end;

    signal ram : memory_t := initialize("mydat.dat");

begin
    bsy <= busy;

    process(enable, clock)
    begin
        if enable = '0' then
            done <= '0';
            busy <= '0';
        end if;
        if rising_edge(clock) and enable = '1' then
            if done = '0' and busy = '0' then
                busy <= '1';
                if we = '1' then
                    ram(to_integer(unsigned(addr_b)))   <= data_b(7 downto 0);
                    ram(to_integer(unsigned(addr_b)+1)) <= data_b(15 downto 8);
                    ram(to_integer(unsigned(addr_b)+2)) <= data_b(23 downto 16);
                    ram(to_integer(unsigned(addr_b)+3)) <= data_b(31 downto 24);
                end if;
                q_b <= ram(to_integer(unsigned(addr_b)+3)) & 
                       ram(to_integer(unsigned(addr_b)+2)) & 
                       ram(to_integer(unsigned(addr_b)+1)) &
                       ram(to_integer(unsigned(addr_b)));

                q_a <= ram(to_integer(unsigned(addr_a)+3)) & 
                       ram(to_integer(unsigned(addr_a)+2)) & 
                       ram(to_integer(unsigned(addr_a)+1)) &
                       ram(to_integer(unsigned(addr_a)));
            elsif done = '0' then
                done <= '1';
            elsif done = '1' then
                busy <= '0';
            end if;
        end if;
    end process;
end rtl;

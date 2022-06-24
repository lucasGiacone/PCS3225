library ieee;
use ieee.numeric_bit.all;
use std.textio.all;

entity ram is
    generic(
        addr_s : natural := 64;
        word_s : natural := 32;
        init_f : string  := "ram.dat"
    );
	port 
	(	
        ck      : in  bit;
        rd	    : in  bit;
        wr	    : in  bit;
		addr	: in  bit_vector(addr_s - 1 downto 0);
		data_i	: in  bit_vector(word_s - 1 downto 0);
        data_o		: out bit_vector(word_s - 1 downto 0)
	);
end entity ram;

architecture rtl of ram is
	constant lines : natural := 2**addr_s;
	subtype word_t is bit_vector(word_s - 1 downto 0);
	type memory_t is array(0 to lines-1) of word_t;
    impure function initialize(arq_name: in string) return memory_t is
        file     arq  : text open read_mode is arq_name;
        variable line    : line;
        variable temp_word  : word_t;
        variable temp_mem : memory_t;
        begin
        for i in memory_t'range loop
            readline(arq, line);
            read(line, temp_word);
            temp_mem(i) := temp_word;
        end loop;
        return temp_mem;
    end;
    signal ram_mem : memory_t := initialize(init_f);
begin
    process(ck)
    begin
        if rising_edge(ck) and wr = '1' then
            ram_mem(to_integer(unsigned(addr))) <= data_i;
        end if;
    end process;

    data_o <= ram_mem(to_integer(unsigned(addr))) when rd='1';
end rtl;

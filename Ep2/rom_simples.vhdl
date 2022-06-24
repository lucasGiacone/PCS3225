library ieee;
use ieee.numeric_bit.all;

entity rom_simples is
	port 
	(	
		addr	: in  bit_vector(3 downto 0);
		data	: out bit_vector(7 downto 0)
	);
end entity rom_simples;

architecture rtl of rom_simples is
	constant depth : natural := 2**4;
	subtype word_t is bit_vector(7 downto 0);
	type memory_t is array(0 to depth-1) of word_t;

    signal rom_mem : memory_t := (
        "00000000",
        "00000011",
        "11000000",
        "00001100",
        "00110000",
        "01010101",
        "10101010",
        "11111111",
        "11100000",
        "11100111",
        "00000111",
        "00011000",
        "11000011",
        "00111100",
        "11110000",
        "00001111"
    );

begin
    data <= rom_mem(to_integer(unsigned(addr)));
end rtl;

library ieee;
use ieee.numeric_bit.all;

entity d_register is
    generic (
        width : natural := 4;
        reset_value : natural := 0
    );
    port (
        clock, reset, regWrite : in bit;
        d : in bit_vector(width-1 downto 0);
        q : out bit_vector(width-1 downto 0)
    );
end d_register;


architecture behavior of d_register is
begin
    p0: process(clock, reset, regWrite)
    begin 
        if reset = '1' then
            q <= bit_vector(to_unsigned(reset_value, width));
        elsif regWrite = '1' and clock'event and clock = '1' then
            q <= d;
        end if;
    end process p0;
end architecture behavior;

library ieee;
use ieee.numeric_bit.all;
use ieee.math_real.all;

entity regfile is
    generic (
        reg_n: natural := 10;
        word_s: natural := 64
    );
    port (
        clock:        in    bit;
        reset:        in    bit;
        regWrite:     in    bit;
        rr1, rr2, wr: in    bit_vector(natural(ceil(log2(real(reg_n))))-1 downto 0);
        d:            in    bit_vector(word_s-1 downto 0);
        q1, q2:       out   bit_vector(word_s-1 downto 0)
    );
end regfile;

architecture arch of regfile is
    constant reg_n_bits: natural := natural(ceil(log2(real(reg_n))));

    component d_register is
        generic (
            width : natural := word_s;
            reset_value : natural := 0
        );
        port (
            clock, reset, regWrite : in bit;
            d : in bit_vector(width-1 downto 0);
            q : out bit_vector(width-1 downto 0)
        );
    end component d_register;

    type regOutArrayType is array (reg_n-1 downto 0) of bit_vector (word_s-1 downto 0);
    signal regOutArray: regOutArrayType;

    signal load_vec: bit_vector(reg_n-2 downto 0);

begin
    regOutArray(reg_n-1) <= (others => '0');
    gen_reg: for i in reg_n-2 downto 0 generate
        load_vec(i) <= ('1' and regWrite) when to_integer(unsigned(wr)) = i else '0';
        regi: d_register
        generic map (width => word_s, reset_value => 0)
        port map (clock => clock, reset => reset, regWrite => load_vec(i), d => d, q => regOutArray(i));
    end generate gen_reg;

    q1 <= regOutArray(to_integer(unsigned(rr1)));
    q2 <= regOutArray(to_integer(unsigned(rr2)));
    
end arch;
library ieee;
use ieee.numeric_bit.all;

entity alu_tb is end;

architecture rtl of alu_tb is
    
    component alu is
        generic (
            size : natural := 8
        );
        port (
            A, B : in bit_vector(size-1 downto 0); -- inputs
            F    : out bit_vector(size-1 downto 0); -- output
            S    : in  bit_vector(3 downto 0);
            Z    : out bit; -- zero flag
            Ov   : out bit; -- overflow flag
            Co   : out bit -- carry out
        );
    end component alu;


    signal A, B, F : bit_vector(3 downto 0);
    signal OP: bit_vector(3 downto 0);
    signal Z, Ov, Co : bit;


    type pattern_type is record
        --  Entradas
        A : bit_vector (3 downto 0);
        B : bit_vector (3 downto 0);
        OP: bit_vector (3 downto 0);;
        --  Saidas
        F  : bit_vector (3 downto 0);
        Z  : bit;
        Ov : bit;
        Co : bit;
    end record;
    type pattern_array is array (natural range <>) of pattern_type;
    constant patterns : pattern_array :=(
        ("0000","0000","0000","0000",'0','0','0')
        ("0000","0000","0000","0000",'0','0','0')
        ("0000","0000","0000","0000",'0','0','0')
    );


begin
    ULA: alu
    generic map(4)
    port map(A, B, F, OP, Z, Ov, Co);

    tb: process
    begin
        report "Add test" severity note;

    end process tb;
    
end architecture rtl;
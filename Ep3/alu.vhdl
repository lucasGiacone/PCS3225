library ieee;
use ieee.numeric_bit.all;

entity alu is
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
end entity alu;

entity bitOperation is
    port (
        A_in, B_in, Less : in bit; -- inputs
        Res              : out bit; -- output
        Set              : out bit;
        A_invert : in bit;
        B_invert : in bit;
        S    : in bit_vector(1 downto 0); -- op selection
        Ci   : in bit; -- carry in
        Co   : out bit -- carry out
    );
end entity bitOperation;

architecture whenElse of bitOperation is
    signal A : bit;
    signal B : bit;
    signal AXB : bit;
    signal SUM : bit;
begin
    A <= A_in when A_invert = '0' else not A_in;
    B <= B_in when B_invert = '0' else not B_in;
    AXB <= A xor B;
    Sum <= AXB xor ci;

    Set <= Sum;

    Res <= A and B  when S = "00" else
           A or B   when S = "01" else
           Sum      when S = "10" else
           Less     when S = "11";

    Co <= (A and B) or (Ci and AXB);
end architecture whenElse;


architecture combinatory of alu is

    component bitOperation
        port (
            A_in, B_in, Less : in bit; -- inputs
            Res              : out bit; -- output
            Set              : out bit;
            A_invert : in bit;
            B_invert : in bit;
            S    : in bit_vector(1 downto 0); -- op selection
            Ci   : in bit; -- carry in
            Co   : out bit -- carry out
        );
    end component;

    signal carry: bit_vector (size downto 0);
    signal bitResult: bit_vector (size-1 downto 0);
    signal less: bit_vector(size-1 downto 0);
    signal sets: bit_vector(size-1 downto 0);
begin
    carry(0) <= S(2);

    less <= (0 => sets(size -1) ,others => '0');

    gen: for i in size-1 downto 0 generate
        boi: bitOperation 
        port map (
            A_in => A(i),
            B_in => B(i),
            Less => less(i),
            Res => bitResult(i),
            Set => sets(i),
            S => S(1 downto 0),
            A_invert => S(3),
            B_invert => S(2),
            Ci => carry(i),
            Co => carry(i+1)
        );
    end generate gen;

    F <= bitResult;
    Z <= '1' when unsigned(bitResult) = 0 else '0';
    Ov <= carry(size) xor carry(size-1);
    Co <= carry(size);

end architecture combinatory;
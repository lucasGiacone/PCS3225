library ieee;
use ieee.numeric_std.all;

entity controlunit is
    port (
    -- To Datapath
    reg2loc : out bit;
    uncondBranch : out bit;
    branch : out bit;
    memRead : out bit;
    memToReg : out bit;
    aluOp : out bit_vector(1 downto 0);
    memWrite : out bit;
    aluSrc : out bit;
    regWrite : out bit;
    -- From Datapath
    opcode : in bit_vector(10 downto 0)
    );
end entity;


architecture arch of controlunit is
    signal mapper: bit_vector(9 downto 0);

begin

    mapper <= "1101110000" when opcode = "11111000010" else
              "1101001000" when opcode = "11111000000" else
              "1001000101" when opcode(10 downto 3) = "10110100" else
              "1011000000" when opcode(10 downto 5) = "000101" else
              "0000100010";

    reg2loc <= mapper(9);
    aluSrc <= mapper(8);
    uncondBranch <= mapper(7);
    memToReg <= mapper(6);
    regWrite <= mapper(5);
    memRead <= mapper(4);
    memWrite <= mapper(3);
    branch <= mapper(2);
    aluOp <= mapper(1 downto 0);
end architecture;

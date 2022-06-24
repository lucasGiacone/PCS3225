library ieee;
use ieee.numeric_bit.all;

entity sign_extend_tb is end;

architecture rtl of sign_extend_tb is
    
    component signExtend is
        port (
            i: in bit_vector(31 downto 0);
            o: out bit_vector(63 downto 0)
        );
    end component signExtend;

    signal input: bit_vector(31 downto 0);
    signal output: bit_vector(63 downto 0);

    function to_bstring(sl : bit) return string is
        variable sl_str_v : string(1 to 3);  -- std_logic image with quotes around
    begin
        sl_str_v := bit'image(sl);
        return "" & sl_str_v(2);  -- "" & character to get string
    end function;
      
    function to_bstring(slv : bit_vector) return string is
        alias    slv_norm : bit_vector(1 to slv'length) is slv;
        variable sl_str_v : string(1 to 1);  -- String of std_logic
        variable res_v    : string(1 to slv'length);
    begin
        for idx in slv_norm'range loop
          sl_str_v := to_bstring(slv_norm(idx));
          res_v(idx) := sl_str_v(1);
        end loop;
        return res_v;
    end function;

begin

    SE : signExtend
        port map(i => input, o => output);

    tb: process
    begin
        input <= "11111000010"&"000000100"&"00"&"00000"&"00000";
        wait for 1 ns;
        assert output = "0000000000000000000000000000000000000000000000000000000000000100" report "wrong value:" & to_bstring(output) severity note;

        input <= "11111000000"&"100000100"&"00"&"00000"&"00000";
        wait for 1 ns;
        assert output = "1111111111111111111111111111111111111111111111111111111100000100" report "wrong value:" & to_bstring(output) severity note;

        input <= "000101"&"00000000000000000000000010";
        wait for 1 ns;
        assert output = "0000000000000000000000000000000000000000000000000000000000000010" report "wrong value:" & to_bstring(output) severity note;

        input <= "000101"&"10000000000000000000000010";
        wait for 1 ns;
        assert output = "1111111111111111111111111111111111111110000000000000000000000010" report "wrong value:" & to_bstring(output) severity note;

        input <= "10110100"&"0000000000000000110"&"00000";
        wait for 1 ns;
        assert output = "0000000000000000000000000000000000000000000000000000000000000110" report "wrong value:" & to_bstring(output) severity note;

        input <= "10110100"&"1000000000000000110"&"00000";
        wait for 1 ns;
        assert output = "1111111111111111111111111111111111111111111111000000000000000110" report "wrong value:" & to_bstring(output) severity note;

        input <= "10010100"&"1000000000000000110"&"00000";
        wait for 1 ns;
        assert output = "0000000000000000000000000000000000000000000000000000000000000000" report "wrong value:" & to_bstring(output) severity note;

        input <= "10010100"&"0000000000000000110"&"00000";
        wait for 1 ns;
        assert output = "0000000000000000000000000000000000000000000000000000000000000000" report "wrong value:" & to_bstring(output) severity note;


        wait;
    end process tb;
    
    
    
end architecture rtl;


--LDUR D 11111000010
--STUR D 11111000000
--CBZ  CB 10110100
--B    B 000101
--ADD  R 10001011000
--SUB  R 11001011000
--AND  R 10001010000
--ORR  R 10101010000
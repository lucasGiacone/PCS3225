library ieee;
use ieee.numeric_bit.all;
use ieee.math_real.all;

entity regfile_tb is end;

architecture rtl of regfile_tb is

    component regfile is
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
    end component regfile;

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

    signal Clk: bit;
    signal finished1, finished2: bit := '0';
    signal reset: bit := '0';
    signal regWrite: bit;

    signal rr1: bit_vector(1 downto 0);
    signal rr2: bit_vector(1 downto 0);
    signal wr: bit_vector(1 downto 0);

    signal data: bit_vector(3 downto 0);
    signal rdd1: bit_vector(3 downto 0);
    signal rdd2: bit_vector(3 downto 0);

    constant HalfPeriod: time := 5 ns;

    signal reset2, regWrite2: bit;
    signal rr12, rr22, wr2: bit_vector(3 downto 0); -- 10 regs
    signal data2, rdd12, rdd22: bit_vector(4 downto 0); -- 5 bits

    signal finished: bit;
begin
    finished <= finished1 and finished2;
    Clk <= not Clk after HalfPeriod when finished /= '1' else '0';

    rf: regfile
    generic map (4, 4)
    port map(clock => Clk, reset => reset, regWrite => regWrite, rr1 => rr1, rr2 => rr2, wr => wr, d => data, q1 => rdd1, q2 => rdd2);

    tb1: process
    begin
        -- Teste escrita normal

        regWrite <= '1';
        rr1 <= "00";
        rr2 <= "11";
        wr  <= "00";
        data <= "0001";
        wait until Clk = '1'; -- Escrita feita
        regWrite <= '0';
        wait for 1 ns; -- Wait para assert
        assert rdd1 = "0001" report "Wrong value: "&to_bstring(rdd1) severity note;
        wait until Clk = '0';


        regWrite <= '1';
        rr1 <= "01";
        rr2 <= "11";
        wr  <= "01";
        data <= "0010";
        wait until Clk = '1'; -- Escrita feita
        regWrite <= '0';
        wait for 1 ns; -- Wait para assert
        assert rdd1 = "0010" report "Wrong value: "&to_bstring(rdd1) severity note;
        wait until Clk = '0';


        regWrite <= '1';
        rr1 <= "10";
        rr2 <= "11";
        wr  <= "10";
        data <= "0011";
        wait until Clk = '1'; -- Escrita feita
        regWrite <= '0';
        wait for 1 ns; -- Wait para assert
        assert rdd1 = "0011" report "Wrong value: "&to_bstring(rdd1) severity note;
        wait until Clk = '0';


        -- Teste escrita em 0

        regWrite <= '1';
        rr1 <= "11";
        rr2 <= "11";
        wr  <= "11";
        data <= "1111";
        wait until Clk = '1'; -- Escrita feita
        regWrite <= '0';
        wait for 1 ns; -- Wait para assert
        assert rdd1 = "0000" report "Wrong value: "&to_bstring(rdd1) severity note;
        wait until Clk = '0';


        -- Teste leitura

        rr1 <= "00";
        rr2 <= "01";
        wr  <= "00";
        data <= "1111";
        wait until Clk = '1'; -- Escrita feita
        regWrite <= '0';
        wait for 1 ns; -- Wait para assert
        assert rdd1 = "0001" report "Wrong value: "&to_bstring(rdd1) severity note;
        assert rdd2 = "0010" report "Wrong value: "&to_bstring(rdd2) severity note;
        wait until Clk = '0';


        -- Teste leitura assincrona

        wait for 1 ns;
        rr1 <= "10";
        rr2 <= "11";
        wr  <= "10";
        data <= "1111";
        wait until Clk = '1'; -- Escrita feita
        regWrite <= '0';
        wait for 1 ns; -- Wait para assert
        assert rdd1 = "0011" report "Wrong value: "&to_bstring(rdd1) severity note;
        assert rdd2 = "0000" report "Wrong value: "&to_bstring(rdd2) severity note;
        wait until Clk = '0';


        -- Teste reset

        reset <= '1';
        rr1 <= "00";
        rr2 <= "01";
        wr  <= "00";
        data <= "1111";
        wait until Clk = '1'; -- Escrita feita
        regWrite <= '0';
        reset <= '0';
        wait for 1 ns; -- Wait para assert
        assert rdd1 = "0000" report "Wrong value: "&to_bstring(rdd1) severity note;
        assert rdd2 = "0000" report "Wrong value: "&to_bstring(rdd2) severity note;
        wait until Clk = '0';

        finished1 <= '1';
        wait;
    end process tb1;

    rf2: regfile
    generic map (10, 5)
    port map(clock => Clk, reset => reset2, regWrite => regWrite2, rr1 => rr12, rr2 => rr22, wr => wr2, d => data2, q1 => rdd12, q2 => rdd22);

    tb2: process
    begin
        -- Teste escrita normal

        regWrite2 <= '1';
        rr12 <= "0000";
        rr22 <= "1001";
        wr2  <= "0000";
        data2 <= "00001";
        wait until Clk = '1'; -- Escrita feita
        regWrite2 <= '0';
        wait for 1 ns; -- Wait para assert
        assert rdd12 = "00001" report "Wrong value: "&to_bstring(rdd12) severity note;
        wait until Clk = '0';


        regWrite2 <= '1';
        rr12 <= "0001";
        rr22 <= "1001";
        wr2  <= "0001";
        data2 <= "00100";
        wait until Clk = '1'; -- Escrita feita
        regWrite2 <= '0';
        wait for 1 ns; -- Wait para assert
        assert rdd12 = "00100" report "Wrong value: "&to_bstring(rdd12) severity note;
        wait until Clk = '0';


        regWrite2 <= '1';
        rr12 <= "0101";
        rr22 <= "1001";
        wr2  <= "0101";
        data2 <= "00110";
        wait until Clk = '1'; -- Escrita feita
        regWrite2 <= '0';
        wait for 1 ns; -- Wait para assert
        assert rdd12 = "00110" report "Wrong value: "&to_bstring(rdd12) severity note;
        wait until Clk = '0';


        -- Teste escrita em 0

        regWrite2 <= '1';
        rr12 <= "1001";
        rr22 <= "1001";
        wr2  <= "1001";
        data2 <= "11111";
        wait until Clk = '1'; -- Escrita feita
        regWrite2 <= '0';
        wait for 1 ns; -- Wait para assert
        assert rdd12 = "00000" report "Wrong value: "&to_bstring(rdd12) severity note;
        wait until Clk = '0';


        -- Teste leitura

        rr12 <= "0000";
        rr22 <= "0001";
        wr2  <= "0001";
        data2 <= "11111";
        wait until Clk = '1'; -- Escrita feita
        regWrite2 <= '0';
        wait for 1 ns; -- Wait para assert
        assert rdd12 = "00001" report "Wrong value: "&to_bstring(rdd12) severity note;
        assert rdd22 = "00100" report "Wrong value: "&to_bstring(rdd22) severity note;
        wait until Clk = '0';


        -- Teste leitura assincrona

        wait for 1 ns;
        rr12 <= "0101";
        rr22 <= "1001";
        wr2  <= "0101";
        data2 <= "11111";
        wait until Clk = '1'; -- Escrita feita
        regWrite2 <= '0';
        wait for 1 ns; -- Wait para assert
        assert rdd12 = "00110" report "Wrong value: "&to_bstring(rdd12) severity note;
        assert rdd22 = "00000" report "Wrong value: "&to_bstring(rdd22) severity note;
        wait until Clk = '0';


        -- Teste reset

        reset2 <= '1';
        rr12 <= "0000";
        rr22 <= "0001";
        wr2  <= "0001";
        data2 <= "11111";
        wait until Clk = '1'; -- Escrita feita
        regWrite2 <= '0';
        reset2 <= '0';
        wait for 1 ns; -- Wait para assert
        assert rdd12 = "00000" report "Wrong value: "&to_bstring(rdd12) severity note;
        assert rdd22 = "00000" report "Wrong value: "&to_bstring(rdd22) severity note;
        wait until Clk = '0';

        finished2 <= '1';
        wait;
    end process tb2;

        
end architecture rtl;
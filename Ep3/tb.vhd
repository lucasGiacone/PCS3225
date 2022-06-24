-- Não submeter esse arquivo!

library ieee;
USE ieee.math_real.ceil;
USE ieee.math_real.log2;

use work.utils.all;

entity tb is
end tb;

architecture tb of tb is
    signal clock, reset, regWrite : bit;

    signal d_9x7, q1_9x7, q2_9x7 : bit_vector(8 downto 0);
    signal wr_9x7, rr1_9x7, rr2_9x7 : bit_vector(2 downto 0);

    constant CLK_PERIOD : time := 10 ns;
    constant LAG_PERIOD : time := 1 ps;
    signal ENDSIM : boolean;
begin
	UUT_9x7 : entity work.regfile
        generic map (word_s => 9, reg_n => 7)
        port map (
        	clock => clock,
            reset => reset,
            regWrite => regWrite,
            d => d_9x7,
            q1 => q1_9x7,
            q2 => q2_9x7,
            wr => wr_9x7,
            rr1 => rr1_9x7,
            rr2 => rr2_9x7);

    tb1 : process
        variable expected3: bit_vector(2 downto 0);
        variable expected9: bit_vector(8 downto 0);
        begin
        	clock <= '0';
        	wait for LAG_PERIOD;

        	-- Ensure everythin is "clean" when we start
        	expected9 := (others => '0');
        	assert (q1_9x7 = expected9)
            report "ghdlfiddle:BAD [wordSize=9, n=7] Banco de registradores deve ter saída q1 nula no início: "&bin(q1_9x7)&" != "&bin(expected9)
                severity error;
            assert (q2_9x7 = expected9)
            report "ghdlfiddle:BAD [wordSize=9, n=7] Banco de registradores deve ter saída q2 nula no início: "&bin(q2_9x7)&" != "&bin(expected9)
                severity error;

            -- Let's try to write without regWrite
            regWrite <= '0';
            d_9x7 <= "000101010";
            wr_9x7 <= "000";
            rr1_9x7 <= "000";
            rr2_9x7 <= "110";
            expected9 := (others => '0');

            clock <= '1';
        	wait for LAG_PERIOD;

        	assert (q1_9x7 = expected9)
            report "ghdlfiddle:BAD [wordSize=9, n=7] Os valores só devem ser salvos caso regWrite = '1': "&bin(q1_9x7)&" != "&bin(expected9)
                severity error;
            assert (q2_9x7 = expected9)
            report "ghdlfiddle:BAD [wordSize=9, n=7] O último registrador deve ser sempre nulo: "&bin(q2_9x7)&" != "&bin(expected9)
                severity error;

            clock <= '0';
        	wait for LAG_PERIOD;

        	-- Let's try to write with regWrite
        	regWrite <= '1';
        	d_9x7 <= "000101010";
            wr_9x7 <= "010";
            rr1_9x7 <= "010";
            rr2_9x7 <= "110";

            clock <= '1';
        	wait for LAG_PERIOD;

            expected9 := "000101010";
        	assert (q1_9x7 = expected9)
            report "ghdlfiddle:BAD [wordSize=9, n=7] O valor deveria ter mudado: "&bin(q1_9x7)&" != "&bin(expected9)
                severity error;
            expected9 := "000000000";
            assert (q2_9x7 = expected9)
            report "ghdlfiddle:BAD [wordSize=9, n=7] O último registrador deve ser sempre nulo: "&bin(q2_9x7)&" != "&bin(expected9)
                severity error;

            -- Let's try to write with regWrite
            clock <= '0';
        	wait for LAG_PERIOD;

        	regWrite <= '1';
        	d_9x7 <= "000101011";
            wr_9x7 <= "001";
            rr1_9x7 <= "010";
            rr2_9x7 <= "001";

            clock <= '1';
        	wait for LAG_PERIOD;

            expected9 := "000101010";
        	assert (q1_9x7 = expected9)
            report "ghdlfiddle:BAD [wordSize=9, n=7] O valor NAO deveria ter mudado: "&bin(q1_9x7)&" != "&bin(expected9)
                severity error;
            expected9 := "000101011";
            assert (q2_9x7 = expected9)
            report "ghdlfiddle:BAD [wordSize=9, n=7] O valor deveria ter mudado: "&bin(q2_9x7)&" != "&bin(expected9)
                severity error;

            -- Let's try to write to the last register
            clock <= '0';
        	wait for LAG_PERIOD;

        	regWrite <= '1';
        	d_9x7 <= "000101011";
            wr_9x7 <= "110";
            rr1_9x7 <= "010";
            rr2_9x7 <= "110";

            clock <= '1';
        	wait for LAG_PERIOD;

            expected9 := "000101010";
        	assert (q1_9x7 = expected9)
            report "ghdlfiddle:BAD [wordSize=9, n=7] O valor NAO deveria ter mudado: "&bin(q1_9x7)&" != "&bin(expected9)
                severity error;
            expected9 := "000000000";
            assert (q2_9x7 = expected9)
            report "ghdlfiddle:BAD [wordSize=9, n=7] O último registrador deve ser sempre nulo: "&bin(q2_9x7)&" != "&bin(expected9)
                severity error;

            -- Testing reset
            reset <= '1';
            wait for LAG_PERIOD;

            expected9 := "000000000";
        	--assert (q1_9x7 = expected9)
            --report "ghdlfiddle:BAD [wordSize=9, n=7] O reset é assíncrono: "&bin(q1_9x7)&" != "&bin(expected9)
                --severity error;
            expected9 := "000000000";
            assert (q2_9x7 = expected9)
            report "ghdlfiddle:BAD [wordSize=9, n=7] O reset é assíncrono: "&bin(q2_9x7)&" != "&bin(expected9)
                severity error;

            rr1_9x7 <= "001";
            rr2_9x7 <= "010";

            wait for LAG_PERIOD;

            expected9 := "000000000";
        	--assert (q1_9x7 = expected9)
            --report "ghdlfiddle:BAD [wordSize=9, n=7] O reset é assíncrono: "&bin(q1_9x7)&" != "&bin(expected9)
                --severity error;
            expected9 := "000000000";
            --assert (q2_9x7 = expected9)
            --report "ghdlfiddle:BAD [wordSize=9, n=7] O reset é assíncrono: "&bin(q2_9x7)&" != "&bin(expected9)
                --severity error;


            report "ghdlfiddle:GOOD Simulação encerrada!";
            ENDSIM <= true;
            wait;
        end process;
end tb;
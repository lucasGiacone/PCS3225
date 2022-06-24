library ieee;
use ieee.numeric_std.all;

entity ram_tb is end;


architecture dut of ram_tb is
    component ram is
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
    end component ram;

    
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

    constant HalfPeriod: time := 5 ns;
    signal Clk: bit;
    signal rd, wr : bit;
    signal data_o : bit_vector(8 downto 0);
    signal data_i : bit_vector(8 downto 0);
    signal addr : bit_vector(3 downto 0);
    signal finished : bit := '0';

begin
    
    Clk <= not Clk after HalfPeriod when finished /= '1' else '0';


    ram_mem: ram
        generic map(4, 9, "rom.dat")
        port map(ck => Clk, rd => rd, wr => wr, addr => addr, data_i => data_i, data_o => data_o);
    
  
    tp: process
    begin
        report "Begin of teste" severity note;

        addr <= "0000";
        rd <= '1';
        assert data_o = "000000000" report "Valor lido incorreto: " & to_bstring(data_o) severity note;

        wait until Clk = '1';
        rd <= '0';
        wait until Clk = '0';
        

        addr <= "0001";
        rd <= '1';
        assert data_o = "000000110" report "Valor lido incorreto: " & to_bstring(data_o) severity note;

        wait until Clk = '1';
        rd <= '0';
        wait until Clk = '0';

        addr <= "1111";
        rd <= '1';
        assert data_o = "000011110" report "Valor lido incorreto: " & to_bstring(data_o) severity note;

        wait until Clk = '1';
        rd <= '0';
        wait until Clk = '0';
        
        addr <= "0001";
        wait for 1 ns;
        rd <= '1';

        assert data_o = "000000110" report "Valor lido incorreto: " & to_bstring(data_o) severity note;

        wait until Clk = '1';
        rd <= '0';
        wait until Clk = '0';


        report "End of teste" severity note;
        finished <= '1';
        wait;
    end process tp;

end architecture dut; 
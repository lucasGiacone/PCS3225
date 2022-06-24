library ieee;

entity rom_tb is end;


architecture dut of rom_tb is
    component rom is
        generic(
            addr_s : natural := 64;
            word_s : natural := 32;
            init_f : string  := "rom.dat"
        );
        port 
        (	
            addr	: in  bit_vector(addr_s - 1 downto 0);
            data	: out bit_vector(word_s - 1 downto 0)
        );
    end component rom;

    signal data : bit_vector(8 downto 0);
    signal addr : bit_vector(3 downto 0);

    
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
    
    rom_mem: rom
        generic map(4, 9, "rom.dat")
        port map(addr, data);
    
  
    tp: process
    begin
        addr <= "0000";
        wait for 5 ns;
        assert data = "000000000" report "Valor lido incorreto: " & to_bstring(data) severity note;

        wait for 5 ns;

        addr <= "0001";
        wait for 5 ns;
        assert data = "000000110" report "Valor lido incorreto: " & to_bstring(data) severity note;

        wait for 5 ns;

        addr <= "1111";
        wait for 5 ns;
        assert data = "000011110" report "Valor lido incorreto: " & to_bstring(data) severity note;
        
        wait;
    end process tp;

end architecture dut; 
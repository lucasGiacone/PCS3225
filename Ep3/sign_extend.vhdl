library ieee;
use ieee.numeric_bit.all;

entity signExtend is
    port (
        i: in bit_vector(31 downto 0);
        o: out bit_vector(63 downto 0)
    );
end entity signExtend;

architecture rtl of signExtend is
    type instuction_t is (d, b, cb, invalid);

    signal tipo: instuction_t;

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


    function extend(x: bit_vector; start: natural; size_auxiliar: natural) return bit_vector is
        variable y : bit_vector(size_auxiliar-1 downto 0);
    begin
        if x(x'length-1 + start) = '1' then
            y := bit_vector(to_signed(-1, size_auxiliar));
        else
            y := bit_vector(to_unsigned(0, size_auxiliar));
        end if;
        y(x'length - 1 downto 0) := x;
        return y;
    end function extend;

    function is_d(opcode: bit_vector(10 downto 0)) return boolean is
    begin
        if opcode = "11111000000" then
            return true;
        end if;
        if opcode = "11111000010" then
            return true;
        end if;
        return false;
    end function is_d;

    function is_cb(opcode: bit_vector(7 downto 0)) return boolean is
    begin
        if opcode = "10110100" then
            return true;
        end if;
        return false;
    end function is_cb;

    function is_b(opcode: bit_vector(5 downto 0)) return boolean is
    begin
        if opcode = "000101" then
            return true;
        end if;
        return false;
    end function is_b;

    signal d_opcode: bit_vector(10 downto 0);
    signal b_opcode: bit_vector(5 downto 0);
    signal cb_opcode: bit_vector(7 downto 0);

begin
    d_opcode  <= i(31 downto 21);
    b_opcode  <= i(31 downto 26);
    cb_opcode <= i(31 downto 24);

    tipo <= d  when is_d(d_opcode) else
            cb when is_cb(cb_opcode) else
            b  when is_b(b_opcode) else
            invalid;

    with tipo select o <=
        extend(i(20 downto 12),12, 64) when d,
        extend(i(25 downto 0),0, 64) when b,
        extend(i(23 downto 5),5, 64) when cb,
        (others => '0') when invalid;
end architecture rtl;
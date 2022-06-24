library ieee;
use ieee.numeric_bit.all;

entity shiftleft2 is
generic (
    ws : natural:=64
);
port (
    i:  in  bit_vector  (ws - 1 downto 0);
    o:  out bit_vector  (ws - 1 downto 0)
);
end shiftleft2;

architecture arch of shiftleft2 is
begin
    o <= i(ws-3 downto 0)&"00";
end architecture;

----------------------------------------------------------

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

--------------------------------------------------------------------

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

--------------------------------------------------------------------

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

--------------------------------------------------------------------
library ieee;
use ieee.numeric_bit.all;
use ieee.math_real.all;

entity datapath is
port (
    -- Common
    clock : in bit;
    reset : in bit;
    -- From Control Unit
    reg2loc : in bit;
    pcsrc : in bit;
    memToReg : in bit;
    aluCtrl : in bit_vector(3 downto 0);
    aluSrc : in bit;
    regWrite : in bit;
    -- To Control Unit
    opcode : out bit_vector(10 downto 0);
    zero : out bit;
    -- IM interface
    imAddr : out bit_vector(63 downto 0);
    imOut : in bit_vector(31 downto 0);
    -- DM interface
    dmAddr : out bit_vector(63 downto 0);
    dmIn : out bit_vector(63 downto 0);
    dmOut : in bit_vector(63 downto 0)
);
end entity datapath;


architecture rtl of datapath is
    
    component d_register is
        generic (
            width : natural := 64;
            reset_value : natural := 0
        );
        port (
            clock, reset, regWrite : in bit;
            d : in bit_vector(width-1 downto 0);
            q : out bit_vector(width-1 downto 0)
        );
    end component d_register;

    component signExtend is
        port (
            i: in bit_vector(31 downto 0);
            o: out bit_vector(63 downto 0)
        );
    end component signExtend;

    component shiftleft2 is
        generic (
            ws : natural:=64
        );
        port (
            i:  in  bit_vector  (ws - 1 downto 0);
            o:  out bit_vector  (ws - 1 downto 0)
        );
    end component shiftleft2;

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

    --PC SIGNALS
    signal pcIn, pcOut, pcOutPlusFour, pcOutPlusImm: bit_vector(63 downto 0);

    --IM SIGNALS
    signal instruction: bit_vector(31 downto 0);

    --IMM SIGNALS
    signal extendedImm, shiftedImm: bit_vector(63 downto 0);

    --REGFILE SIGNALS
    signal selReg: bit_vector(4 downto 0);
    signal regData, regRead1, regRead2: bit_vector(63 downto 0);

    --ALU SIGNAL
    signal aluIn2, aluOut: bit_vector(63 downto 0);
    signal overflow, carry: bit;
begin
    
    --PC DATA PATH

    PC: d_register
    generic map (width => 64, reset_value => 0)
    port map (clock => clock, reset => reset, regWrite => '1', d => pcIn, q => pcOut);

    SE: signExtend
    port map (i=>instruction, o=>extendedImm);

    SL2: shiftleft2
    generic map(ws => 64)
    port map(i=>extendedImm, o => shiftedImm);

    pcOutPlusFour <= bit_vector(unsigned(pcOut) + 4);
    pcOutPlusImm <=  bit_vector(unsigned(pcOut) + unsigned(shiftedImm));

    pcIn <= pcOutPlusFour when pcsrc = '0' else pcOutPlusImm;

    ---INSTRUCTION MEMORY
    imAddr <= pcOut;
    instruction <= imOut;

    ---REGFILE
    RF: regfile
    generic map ( reg_n => 32, word_s => 64)
    port map (clock => clock, reset=> reset, regWrite=>regWrite, rr1=>instruction(9 downto 5), rr2 => selReg, wr => instruction(4 downto 0),
        d => regData, q1 => regRead1, q2 => regRead2);

    selReg <= instruction(20 downto 16) when reg2loc = '0' else instruction(4 downto 0);

    opcode <= instruction(31 downto 21);
    
    ULA: alu
    generic map (size => 64)
    port map(A => regRead1, B => aluIn2, F => aluOut, S => aluCtrl, Z => zero, Ov => overflow, Co => carry);

    aluIn2 <= regRead2 when aluSrc = '0' else extendedImm;

    regData <= aluOut when memToReg = '0' else dmOut;

end architecture rtl;
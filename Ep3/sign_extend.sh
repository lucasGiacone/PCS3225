ghdl -a sign_extend.vhdl
ghdl -e signExtend
ghdl -a sign_extend_tb.vhdl
ghdl -e sign_extend_tb
ghdl -r sign_extend_tb --wave=signExtend.ghw
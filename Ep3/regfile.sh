ghdl -a regfile.vhdl
ghdl -e regfile
ghdl -a regfile_tb.vhdl
ghdl -e regfile_tb
ghdl -r regfile_tb --wave=regfile.ghw
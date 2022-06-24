ghdl -a ram.vhdl
ghdl -e ram
ghdl -a ram_tb.vhdl
ghdl -e ram_tb
ghdl -r ram_tb --wave=ram.ghw
exit 0
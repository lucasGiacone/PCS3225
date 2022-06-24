ghdl -a dpram.vhdl
ghdl -a polistack.vhdl
ghdl -a toplevel.vhdl
ghdl -e toplevel
ghdl -r toplevel --wave=teste.ghw --max-stack-alloc=0
vlib work

vlog -timescale 1ns/1ns snake.v

vsim datapath

log {/*}
add wave {/*}
force {clk} 0 0, 1 1 -r 2

force {resetn} 0 0, 1 4
force {enable} 0 0, 1 5
force {era} 0
force {mov} 0
run 20ns

force {resetn} 0 0, 1 4
force {enable} 0 0, 1 5
force {era} 1
force {mov} 0
run 20ns

force {resetn} 0 0, 1 4
force {enable} 0 0, 1 5
force {era} 0
force {mov} 1
run 20ns

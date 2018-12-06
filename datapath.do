vlib work

vlog -timescale 1ns/1ns snakes.v

vsim datapath

log {/*}
add wave {/*}
force {clk} 0 0, 1 1 -r 2
force {direction} 2#

run 20ns

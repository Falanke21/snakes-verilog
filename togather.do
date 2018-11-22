vlib work

vlog -timescale 1ns/1ns snake.v

vsim togather

log {/*}
add wave {/*}
force {resetn} 0 0, 1 10
force {clk} 0 0, 1 1 -r 2
run 1000000ns

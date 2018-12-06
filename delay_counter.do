vlib work

vlog -timescale 1ns/1ns snakes.v

vsim delay_counter

log {/*}
add wave {/*}
force {reset_n} 0 0, 1 4
force {clk} 0 0, 1 1 -r 2
force {en_delay} 0 0, 1 20 -r 40
run 200ns

#------------------------------------------#
# Design Constraints
#------------------------------------------#

# Clock network
set clk_input clk
create_clock [get_ports $clk_input] -name clk -period 25
puts "\[INFO\]: Creating clock {clk} for port $clk_input with period: 25"

# Clock non-idealities
set_propagated_clock [get_clocks {clk}]
set_clock_uncertainty 0.12 [get_clocks {clk}]
puts "\[INFO\]: Setting clock uncertainty to: 0.12"

# Maximum transition time for the design nets
set_max_transition 0.75 [current_design]
puts "\[INFO\]: Setting maximum transition to: 0.75"

# Maximum fanout
set_max_fanout 16 [current_design]
puts "\[INFO\]: Setting maximum fanout to: 16"

# Timing paths delays derate
set_timing_derate -early [expr {1-0.07}]
set_timing_derate -late [expr {1+0.07}]

# Multicycle paths
set_multicycle_path -setup 2 -through [get_ports {en_ready_o}]
set_multicycle_path -hold 1  -through [get_ports {en_ready_o}]
set_multicycle_path -setup 2 -through [get_ports {de_ready_o}]
set_multicycle_path -hold 1  -through [get_ports {de_ready_o}]
set_multicycle_path -setup 2 -through [get_ports {msg_auth}]
set_multicycle_path -hold 1  -through [get_ports {msg_auth}]

set_multicycle_path -setup 2 -through [get_ports {en_start_in}]
set_multicycle_path -hold 1  -through [get_ports {en_start_in}]
set_multicycle_path -setup 2 -through [get_ports {dec_start_in}]
set_multicycle_path -hold 1  -through [get_ports {dec_start_in}]


#------------------------------------------#
# Retrieved Constraints then modified
#------------------------------------------#

# Clock source latency
set usr_clk_max_latency 4.57
set usr_clk_min_latency 4.11
set clk_max_latency 5.70
set clk_min_latency 4.40
set_clock_latency -source -max $clk_max_latency [get_clocks {clk}]
set_clock_latency -source -min $clk_min_latency [get_clocks {clk}]
puts "\[INFO\]: Setting clock latency range: $clk_min_latency : $clk_max_latency"

# Clock input Transition
set_input_transition 0.61 [get_ports $clk_input]

# Input delays
set_input_delay -max 1.87 -clock [get_clocks {clk}] [get_ports {key_in}]
set_input_delay -max 1.89 -clock [get_clocks {clk}] [get_ports {nonce_in}]
set_input_delay -max 3.17 -clock [get_clocks {clk}] [get_ports {associated_in}]
set_input_delay -max 3.74 -clock [get_clocks {clk}] [get_ports {plaintext_in}]
set_input_delay -max 3.89 -clock [get_clocks {clk}] [get_ports {en_start_in}]
set_input_delay -max 4.13 -clock [get_clocks {clk}] [get_ports {dec_start_in}]
set_input_delay -max 4.61 -clock [get_clocks {clk}] [get_ports {tag_in}]
set_input_delay -min 0.18 -clock [get_clocks {clk}] [get_ports {key_in}]
set_input_delay -min 0.3 -clock [get_clocks {clk}] [get_ports {nonce_in}]
set_input_delay -min 1.19 -clock [get_clocks {clk}] [get_ports {associated_in}]
set_input_delay -min 0.79 -clock [get_clocks {clk}] [get_ports {plaintext_in}]
set_input_delay -min 1.04 -clock [get_clocks {clk}] [get_ports {en_start_in}]
set_input_delay -min 1.65 -clock [get_clocks {clk}] [get_ports {dec_start_in}]
set_input_delay -min 1.69 -clock [get_clocks {clk}] [get_ports {tag_in}]

# Reset input delay
set_input_delay [expr 25 * 0.5] -clock [get_clocks {clk}] [get_ports {rst}]

# Input Transition
set_input_transition -max 0.14  [get_ports {key_in}]
set_input_transition -max 0.15  [get_ports {nonce_in}]
set_input_transition -max 0.17  [get_ports {associated_in}]
set_input_transition -max 0.18  [get_ports {plaintext_in}]
set_input_transition -max 0.38  [get_ports {en_start_in}]
set_input_transition -max 0.84  [get_ports {dec_start_in}]
set_input_transition -max 0.86  [get_ports {tag_in}]

set_input_transition -min 0.05  [get_ports {key_in}]
set_input_transition -min 0.06  [get_ports {nonce_in}]
set_input_transition -min 0.07  [get_ports {associated_in}]
set_input_transition -min 0.07  [get_ports {plaintext_in}]
set_input_transition -min 0.07  [get_ports {en_start_in}]
set_input_transition -min 0.09  [get_ports {dec_start_in}]
set_input_transition -min 0.09  [get_ports {tag_in}]

# Output delays
set_output_delay -max 1.0 -clock [get_clocks {clk}] [get_ports {ciphertext_o}]
set_output_delay -max 1.0 -clock [get_clocks {clk}] [get_ports {plaintext_o}]
set_output_delay -min 0 -clock [get_clocks {clk}] [get_ports {ciphertext_o}]
set_output_delay -min 0 -clock [get_clocks {clk}] [get_ports {plaintext_o}]
set_output_delay -max 1.0 -clock [get_clocks {clk}] [get_ports {tag_o}]
set_output_delay -max 1.0 -clock [get_clocks {clk}] [get_ports {dectag_o}]
set_output_delay -min 0 -clock [get_clocks {clk}] [get_ports {tag_o}]
set_output_delay -min 0 -clock [get_clocks {clk}] [get_ports {dectag_o}]
set_output_delay -max 8.41 -clock [get_clocks {clk}] [get_ports {en_ready_o}]
set_output_delay -max 8.41 -clock [get_clocks {clk}] [get_ports {de_ready_o}]
set_output_delay -min 1.37 -clock [get_clocks {clk}] [get_ports {en_ready_o}]
set_output_delay -min 1.37 -clock [get_clocks {clk}] [get_ports {de_ready_o}]
set_output_delay -max 8.41 -clock [get_clocks {clk}] [get_ports {msg_auth}]
set_output_delay -min 1.37 -clock [get_clocks {clk}] [get_ports {msg_auth}]





# Output loads
set_load 0.19 [all_outputs]

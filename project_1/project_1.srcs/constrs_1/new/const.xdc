create_clock -period 10.000 -name clk -waveform {0.000 5.000} -add [get_ports -filter { NAME =~  "*clk*" && DIRECTION == "IN" }]


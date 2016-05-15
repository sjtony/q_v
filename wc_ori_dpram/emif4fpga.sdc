create_clock -name inclk_50mhz -period 20.000 -waveform { 0.000 10.000 } [get_ports { inclk_50mhz}]
derive_pll_clocks
derive_clock_uncertainty
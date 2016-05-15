`timescale 1ns / 1ps

//resynthesize = true;
////////////////////////////////////////////////////////////////////////////////
// Company: 	   Kulicke and Soffa
// Engineer:	   SJ HE
//
// Create Date:    01/03/2016
// Design Name:    ATX5 Elite
// Module Name:    
// Project Name:   ATX5 Elite 
// Target Device:  SPARTAN 3E XC3S100E - 7TQ144
// Tool versions:  Altera Quarus 15 
// Description:
// Modify:         added SPI
////////////////////////////////////////////////////////////////////////////////////
module emif4fpga( ctrl_out,
				   sel_led,
				   //ema_wait,
				   ema_cs,
				   ema_we_dqm,
				   ema_a,
				   ema_ba,
				   ema_oe,
				   ema_we,
				   ema_clk,
				   ema_d,
					spi0_simo,
					spi0_somi,
					spi0_clk,
					spi0_scsn4,
					
					g_sensor_sdi,
					g_sensor_sdo,
					g_sensor_sclk,
					g_sensor_cs_n,
					
					tp1_p9_13,
					tp2_p9_24,
					dsp2reg_ctrl,
					inclk_50mhz);

// variable to be used for other module, not for IO input or output
	output	[7:0]ctrl_out;
	//output	ema_wait;

    input 	sel_led;							
    input 	ema_cs;							
    input 	[1:0]ema_we_dqm;							
    input 	[12:0]ema_a;							
    input 	[1:0]ema_ba;							
    input 	ema_oe;							
    input 	ema_we;							
    input 	ema_clk;							
    input 	inclk_50mhz;							
    inout   [15:0] ema_d;
    
	 input 	spi0_simo;							
    input 	spi0_clk;							
    input 	spi0_scsn4;							
	 output	spi0_somi;

    input 	g_sensor_sdo;							
	 output	g_sensor_sdi;
	 output	g_sensor_sclk;
	 output	g_sensor_cs_n;

	 output	tp1_p9_13;
	 output	tp2_p9_24;
	 output	[15:0]dsp2reg_ctrl;
	
	
	// code start here 
	wire 	[7:0]ema_a1;			
	wire 	dpram_oe;			
	wire 	dpram_we;			
	wire 	outclk_50mhz;			
	wire 	[15:0] dpram_dout;
	wire 	[15:0] fpga2dsp;
	wire	[15:0] dpram_din;
	reg 	[15:0] dsp2reg_ctrl = 16'h55aa;
	reg 	[15:0] dsp2reg_add1;
	assign	ema_a1 = {ema_a[6:0],ema_ba[1]};       		// 256 address 
	assign	dpram_din = ema_d;              			// 
	assign	dpram_oe = !ema_oe && !ema_cs;              // dual port mem data output to DSP enable "1" = enable
	assign	dpram_we = !ema_we && !ema_cs;              // dual port mem data output to DSP enable "1" = enable
	assign 	ema_d = dpram_oe ? fpga2dsp : 16'hzzzz;		// always "Z" except reading time

	assign	spi0_somi = g_sensor_sdo;              			// 
	assign	g_sensor_sdi = spi0_simo;              			// 
	assign	g_sensor_sclk = spi0_clk;              			// 
	assign	g_sensor_cs_n = spi0_scsn4;              			// 

	assign	tp1_p9_13 = spi0_scsn4;              			// 
	assign	tp2_p9_24 = spi0_clk;              			// 


   always @(posedge ema_we) begin
		if (!ema_cs) begin
			//dsp2reg_ctrl <= dpram_din;	// dsp write to reg of FPGA at 8001h 
			dsp2reg_add1 <= {8'h8f, ema_a[6:0], ema_ba[1]};	// dsp write to reg of FPGA at 8001h 
			case (ema_a1)
				8'h01   : dsp2reg_ctrl <= dpram_din;	// dsp write to reg of FPGA at 8001h 
			endcase
		end
	end
	
	assign 	fpga2dsp = dpram_dout;		

// Instantiate the module
led_mux	led_mux_inst (
	.data0x ( dsp2reg_ctrl[7:0] ),
	.data1x ( dsp2reg_ctrl[15:8] ),
	.sel ( !sel_led ),
	.result ( ctrl_out )
	);
			
	wire [7:0] 	address_b_sig;
	wire [15:0] data_b_sig;
	wire [15:0] q_b_sig;
	wire  	rden_b_sig;
	wire  	wren_b_sig;
	
dpram	dpram_inst (
	.address_a ( ema_a1 ),
	.address_b ( address_b_sig ),
	.clock ( outclk_50mhz ),
	.data_a ( dpram_din ),
	.data_b ( data_b_sig ),
	.rden_a ( dpram_oe ),
	.rden_b ( rden_b_sig ),
	.wren_a ( dpram_we ),
	.wren_b ( wren_b_sig ),
	.q_a ( dpram_dout ),
	.q_b ( q_b_sig )
	);


altpll_top	altpll_top_inst (
	.inclk0 ( inclk_50mhz ),
	.c0 ( outclk_50mhz )
	);
	
	reg [15:0]tx_databuf;
 	always @(posedge outclk_50mhz) begin
		if (rden_b_sig )   // read comman
			case (address_b_sig)
				8'd4  	: tx_databuf <= 16'haaaa;	// ConnX elite
			default    : tx_databuf <= q_b_sig;//tx_databuf2;  // read from dpram
			endcase
	end

endmodule	 

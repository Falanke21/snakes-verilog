// Part 2 skeleton

module snake
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]

	wire resetn, enable, era, mov;
	assign resetn = KEY[0];

	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";

	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.

    // Instansiate datapath
	// datapath d0(...);
   datapath d0(era, mov, CLOCK_50, resetn, colour, x, y, enable);

    // Instansiate FSM control
    // control c0(...);
	control c0(resetn, CLOCK_50, enable, writeEn, era, mov);

endmodule


module datapath(era, mov, clk, resetn, color_out, x_out, y_out, enable);
   input clk, enable, resetn, era, mov;
	output [6:0] y_out;
	output [7:0] x_out;
	output [2:0] color_out;
	reg [7:0] x_now;
	reg [6:0] y_now;
	reg [2:0] color_now, x_progress;





	always @(posedge clk)
	begin
		if (!resetn)
		begin
		   x_now <= 8'd10;
	      y_now <= 7'd10;
			color_now <= 3'b010;
			x_progress <= 2'b00;
		end
		else if (enable && era )
			color_now <= 3'b000;
		else if (enable && mov)
		begin
		   color_now <= 3'b010;
			x_progress <= x_progress + 1'b1;
		end
	end




   assign x_out = x_now + x_progress;
	assign y_out = y_now;
	assign color_out = color_now;
endmodule

module control( resetn, clk, enable, plot, era, mov);
   input resetn, clk;
	output reg enable, plot, era, mov;
	reg [2:0] previous_state, next_state;
	wire cenable, last;
	wire [27:0] frame,delay;

	localparam 	DRAW = 3'd0,
	            ERASE = 3'd1,
				   MOVE = 3'd2,
					delays = 20'd833333,
				   frams = 24'd12499999;

	ratedivider del(1'b1, {8'b000000, delays}, clk, resetn, delay);
	ratedivider fra(1'b1, {4'b000, frams}, clk, resetn, frame);

	assign last = (delay == 0) ? 1 : 0;
	assign cenable = (frame == 0) ? 1 : 0;


	always @(posedge clk)
	begin
		if (!resetn)
		   previous_state <= DRAW;
		else
			previous_state <= next_state;
	end

	always @(*)
	begin
		case (previous_state)
			DRAW: next_state = cenable ? ERASE : DRAW;
			ERASE: next_state = cenable ? ERASE : MOVE;
			MOVE: next_state = cenable ? MOVE : DRAW;

		endcase
	end

	always @(*) begin
		plot = 1'b0;
		enable = 1'b0;
		era = 1'b0;
		mov = 1'b0;

		case (previous_state)
			DRAW:begin
				plot = 1;
				enable = 1;
				end
			ERASE:begin
				plot = 1;
				enable = 1;
				era = 1;
				end
			MOVE:
			begin
				plot = 1;
		      enable = 1;
		      mov = 1;
			end
		endcase
	end
endmodule

module ratedivider(enable, load, clk, reset_n, q);
	input enable, clk, reset_n;
	input [27:0] load;
	output reg [27:0] q;

	always @(posedge clk)
	begin
		if (reset_n == 1'b0)
			q <= load;
		else if (enable == 1'b1)
			begin
				if (q == 28'd0)
					q <= load;
				else
					q <= q - 1'b1;
			end
	end
endmodule

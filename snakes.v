module snakes
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
		VGA_B,   						//	VGA Blue[9:0]
		PS2_CLK,
		PS2_DAT,
		HEX0,
		HEX1
	);

	input	  CLOCK_50;				//	50 MHz
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
	output   [6:0] HEX0, HEX1;
	inout 			PS2_CLK;
	inout 			PS2_DAT;

	wire resetn;
	assign resetn = SW[9];

	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;
	wire [7:0] scores;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(1),
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

		wire w_k, a_k, s_k, d_k, left_k, right_k, up_k, down_k, space_k, enter_k;
		keyboard_tracker #(.PULSE_OR_HOLD(0)) k0(
	    .clock(CLOCK_50),
		  .reset(SW[9]),
		  .PS2_CLK(PS2_CLK),
		  .PS2_DAT(PS2_DAT),
		  .w(w_k),
		  .a(a_k),
		  .s(s_k),
		  .d(d_k),
		  .left(left_k),
		  .right(right_k),
		  .up(up_k),
		  .down(down_k),
		  .space(space_k),
		  .enter(enter_k)
		  );

		datapath d0(
	         .clk(CLOCK_50),
	         .direction(direction),
				.game_reset(SW[1]),
				.game_display(SW[0]),
		      .RGB(colour),
				.x_position(x),
				.y_position(y),

				.snake_start(SW[2]),
				.score(scores)
	 );
	 
	 hex_decoder hex0(scores[3:0], HEX0);
	 hex_decoder hex1(scores[7:4], HEX1);


	 //direction wire
    wire [3:0] direction;
	 kbInput kbIn(CLOCK_50, KEY, SW, a_k, d_k, w_k, s_k, direction, reset);

endmodule


module datapath(clk, direction, game_reset, game_display, RGB, x_position, y_position ,snake_start, score);
  input clk;

	output [7:0] x_position;
	output [6:0] y_position;
	output [7:0] score;
	input [3:0] direction;

	input snake_start;

	//status of game
   input game_reset;
	input game_display;


	wire R, G, B;
	wire frame_update; // signal for frame update
	wire delayed_clk;

	output [2:0] RGB; // the colour used for output


	//registers for snake
	reg [6:0] size;
	reg [7:0] score;
	reg [7:0] snakeX[0:640];
	reg [6:0] snakeY[0:640];
	reg found;
	reg snakeHead;
	reg snakeBody;
	reg [1:0]currentDirect;
	integer snake_body_counter, snake_body_counter2, snake_body_counter3;
	reg up,down,left,right;

	//registers for food
	reg food;
	reg [7:0] foodX;
	reg [6:0] foodY;
	reg food_inX, food_inY;
	wire [7:0]rand_X;
	wire [6:0]rand_Y;

	//registers for game status
	reg kill, safe;
	reg kill_collision, eat_food, game_over;


	//down level modules
	updatexyPosition ref0(clk, x_position, y_position);
	frame_updater upd0(clk, 1'b1, frame_update);
	delay_counter dc0(clk, 1'b1, frame_update,delayed_clk);
	randomApple rand1(clk, rand_X, rand_Y);

	always@(posedge clk)
	begin
		if (game_reset)begin


			 //initialize snake's position
			 for(snake_body_counter3 = 1; snake_body_counter3 < 641; snake_body_counter3 = snake_body_counter3+1)begin
					snakeX[snake_body_counter3] = 0;
					snakeY[snake_body_counter3] = 0;
			 end

			 //initialze snake's size
			 size = 1;
			 score = 0;

			 //start game
			 game_over=0;

			 //initialize food's position
			 foodX = 15;
			 foodY = 15;

		end
		else if(game_display)begin
				score = score;
				
				//Draw a food
				food_inX <= (x_position >= foodX && x_position <= (foodX + 2));
				food_inY <= (y_position >=foodY && y_position <= (foodY + 2));
				food = food_inX && food_inY;

				//Set food's position
				if(eat_food)begin
						foodX <= rand_X;
						foodY <= rand_Y;
				end
				
				//update snake's position
				if(delayed_clk)begin
					for(snake_body_counter2 = 640; snake_body_counter2 > 0; snake_body_counter2 = snake_body_counter2 - 1)begin
							if(snake_body_counter2 <= size - 1)begin
								snakeX[snake_body_counter2] = snakeX[snake_body_counter2 - 1];
								snakeY[snake_body_counter2] = snakeY[snake_body_counter2 - 1];
							end
					end

					//update snake's direction
					case(direction)
						//UP
						4'b0001: if(!down)begin
											up = 1;
											down = 0;
											left = 0;
											right = 0;
									 end
						//LEFT
						4'b0010:if(!right)begin
											up = 0;
											down = 0;
											left = 1;
											right = 0;
									 end
						//DOWN
						4'b0100:if(!up)begin
											up = 0;
											down = 1;
											left = 0;
											right = 0;
									end
						//RIGHT
						4'b1000: if(!left)begin
											up = 0;
											down = 0;
											left = 0;
											right = 1;
									end
					endcase
					
					if(up)
						 snakeY[0] = (snakeY[0] - 1);
					else if(left)
						 snakeX[0] = (snakeX[0] - 1);
					else if(down)
						 snakeY[0] = (snakeY[0] + 1);
					else if(right)
						 snakeX[0] = (snakeX[0] + 1);
				end
				
				//Add Snake body
				found = 0;
				for(snake_body_counter = 1; snake_body_counter <= size; snake_body_counter = snake_body_counter + 1)begin
					if(~found)begin
						snakeBody = ( (x_position >= snakeX[snake_body_counter] && x_position <= snakeX[snake_body_counter]+2)
								  && (y_position >= snakeY[snake_body_counter] && y_position <= snakeY[snake_body_counter]+2));
						found = snakeBody;
					end
				end

				//Add Snake head
				snakeHead = (x_position >= snakeX[0] && x_position <= (snakeX[0]+2))
								&& (y_position >= snakeY[0] && y_position <= (snakeY[0]+2));


				//Initial Snake's head
				if(!snake_start) begin
					snakeY[0] = 60;
					snakeX[0] = 80;
				end

				
				//if is in kill position
				kill = snakeBody;

				//if is in safe position
				safe = food;

				//check good collision
				if(safe && snakeHead) begin
					eat_food<=1;
					size = size+2;
					score = score + 1;
				end
				else
					eat_food<=0;

				//check bad collision
				if(kill && snakeHead) begin
					kill_collision<=1;
				end
				else begin
					kill_collision<=0;
				end

				//check game over
				if(kill_collision) begin
					game_over<=1;
				end


		end
	end

	// Display green: the snake's head and the snake's body
	// Display red: the food, or game over

	assign R = food;
	assign G = snakeHead||snakeBody;
	assign B = 0;
   assign RGB = {R, G, B};
endmodule


module randomApple(clk, rand_X, rand_Y);
	input clk;
	output reg [7:0] rand_X =6;
	output reg [6:0] rand_Y =6;

	// set the maximum height and width of the game interface.
	// x and y will scan over every pixel.
	integer max_height = 108;
	integer max_width = 154;

	always@(posedge clk)
	begin
		if(rand_X == max_width)
			rand_X <= 6;
		else
			rand_X <= rand_X + 1;
	end

	always@(posedge clk)
	begin
		if(rand_X == max_width)
		begin
			if(rand_Y === max_height)
				rand_Y <= 6;
			else
				rand_Y <= rand_Y + 1;
		end
	end
endmodule


module kbInput(CLOCK_50, KEY, SW, a_k, d_k, w_k, s_k, direction, reset);
	input CLOCK_50;
	input [3:0]KEY;
	input [9:0]SW;
	input a_k, d_k, w_k, s_k;
	output reg [3:0] direction;
	output reg reset = 0;

	always@(*)
	begin
		if(~KEY[2] || w_k)
			direction = 4'b0001;
		else if(~KEY[3] || a_k)
			direction = 4'b0010;
		else if(~KEY[1] || s_k)
			direction = 4'b0100;
		else if(~KEY[0] || d_k)
			direction = 4'b1000;

		else direction <= direction;
	end
endmodule





module updatexyPosition(clk, x_counter, y_counter);
// refreshes the coordinate of x and y to the next check point.
	input clk;
	output reg [7:0] x_counter;
	output reg [6:0] y_counter;

	// set the maximum height and width of the game interface.
	// x and y will scan over every pixel.
	integer max_height = 120;
	integer max_width = 160;

	always@(posedge clk)
	begin
		if(x_counter === max_width)
			x_counter <= 0;
		else
			x_counter <= x_counter + 1;
	end

	always@(posedge clk)
	begin
		if(x_counter === max_width)
		begin
			if(y_counter === max_height)
				y_counter <= 0;
			else
			y_counter <= y_counter + 1;
		end
	end
endmodule

module frame_updater(clk, reset_n, frame_update);
	input clk;
	input reset_n;
	output frame_update;
	reg[19:0] delay;
	// Register for the delay counter

	always @(posedge clk)
	begin: delay_counter
//		if (!reset_n)
//			delay <= 20'd840000;
		if (delay == 0)
			delay <= 20'd840000;
	   else
		begin
			    delay <= delay - 1'b1;
		end
	end

	assign frame_update = (delay == 20'd0)? 1: 0;
endmodule



module delay_counter(clk, reset_n, en_delay,delayed_clk);
	input clk;
	input reset_n;
	input en_delay;
	output delayed_clk;

	reg[3:0] delay;

	// Register for the delay counter
	always @(posedge clk)begin
//		if (!reset_n)
//			delay <= 20'd840000;
		if(delay == 2)
				delay <= 0;
		else if (en_delay)begin
			   delay <= delay + 1'b1;
		end
	end

	assign delayed_clk = (delay == 2)? 1: 0;
endmodule


module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;

    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;
            default: segments = 7'h7f;
        endcase
endmodule

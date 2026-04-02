
module ipdc (                       //Don't modify interface
	input         i_clk,
	input         i_rst_n,
	input         i_op_valid,
	input  [ 3:0] i_op_mode,
    	output        o_op_ready,
	input         i_in_valid,
	input  [23:0] i_in_data,
	output        o_in_ready,
	output        o_out_valid,
	output [23:0] o_out_data
);

// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
// ---- Add your own wires and registers here if needed ---- //

// output regs
reg o_op_ready_r, o_op_ready_w;
reg o_in_ready_r, o_in_ready_w;
reg o_out_valid_r, o_out_valid_w;
reg [23:0] o_out_data_r, o_out_data_w;

reg [2:0] curr_state, next_state;
reg [3:0] curr_op_d, curr_op_q;

reg [23:0] pixels[0:255];
reg [7:0] pixel_ctr_q;

reg [2:0] display_d, display_q; // display size used for scaling and outputting
reg [4:0] image_size_d, image_size_q;

reg [4:0] output_ctr_d, output_ctr_q;

reg [3:0] origin_row_d, origin_row_q, origin_col_d, origin_col_q;


// how much to index by for each display size from the last pixel from a row
// example: for 16by16, with origin 0x0, pixels = 0,1,2,3 (4 + 12 = 16) start of next row, 4 from there and so on

// ^ ignore 



wire [2:0] pixel_offset = (display_q == 3'd2) ? 3'd2 :
                        (display_q == 3'd1) ? 3'd4  : 3'd1;


wire [4:0] max_pixels = (display_q == 3'd4) ? 5'd16 :
                        (display_q == 3'd2) ? 5'd4  : 5'd1;

wire [3:0] row_off_2 = output_ctr_q[1] ? 4'd2 : 4'd0;
wire [3:0] col_off_2 = output_ctr_q[0] ? 4'd2 : 4'd0;

localparam [2:0]
	IDLE = 3'd0,
	LOAD = 3'd1,
	SHIFT = 3'd2,
	SCALE = 3'd3,
	MEDIAN_FILTERING = 3'd4,
	YCbCR = 3'd5,
	CENSUS_TRANF = 3'd6,
	DONE = 3'd7;

// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
// ---- Add your own wire data assignments here if needed ---- //
assign o_op_ready = o_op_ready_r;
assign o_in_ready = o_in_ready_r;
assign o_out_valid = o_out_valid_r;
assign o_out_data = o_out_data_r;



// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //

always @(*) begin
	o_op_ready_w = 0;
	next_state = curr_state;
	curr_op_d = curr_op_q;

	o_in_ready_w = 1'b0;
	o_out_data_w = 0;
	o_out_valid_w = 0;

	display_d = display_q;
	image_size_d = image_size_q;

	origin_row_d = origin_row_q;
	origin_col_d = origin_col_q;

	case (curr_state)
		IDLE : begin
			o_op_ready_w = 1'b1;
			//if ((i_op_mode == 4'b0000) && (i_op_valid == 1'b1)) begin
			//	next_state = LOAD;
			//end 

			case ({i_op_valid, i_op_mode})
				5'b10000 : begin
					next_state = LOAD;
				end
				
				5'b10100, 5'b10101, 5'b10110, 5'b10111 : begin
					next_state = SHIFT;
				end

				5'b11000, 5'b11001 : begin
					next_state = SCALE;
				end

				default : begin 
					next_state = IDLE;
				end
			endcase 
			
			curr_op_d = i_op_mode;
		end

		LOAD : begin
			o_op_ready_w = 1'b0;
			o_in_ready_w = 1'b1;
			if (pixel_ctr_q == 8'd255 && i_in_valid) begin
				next_state = IDLE;
				o_in_ready_w = 1'b0;
			end
		end

		SHIFT : begin
			o_op_ready_w = 1'b0;
		
			// right 
			if (curr_op_q == 4'b0100) begin
				if ((origin_col_q + pixel_offset + display_q) < image_size_q) begin
					origin_col_d = origin_col_q + pixel_offset;
				end
			end

			// left
			if (curr_op_q == 4'b0101) begin
				if ((origin_col_q >= pixel_offset)) begin
					origin_col_d = origin_col_q - pixel_offset;
				end
			end

			// up
			if (curr_op_q == 4'b0110) begin
				if ((origin_row_q >= pixel_offset)) begin
					origin_row_d = origin_row_q - pixel_offset;
				end
			end

			// down
			if (curr_op_q == 4'b0111) begin
				if ((origin_row_q + pixel_offset + display_q) < image_size_q) begin
					origin_row_d = origin_row_q + pixel_offset;
				end
			end
			
			next_state = DONE;
		end


		SCALE : begin
			o_op_ready_w = 1'b0;

			if (curr_op_q == 4'b1000) begin
			    if (display_q > 3'd1)
				display_d = display_q >> 1;
			end

			if (curr_op_q == 4'b1001) begin
			    if (display_q < 3'd4)
				display_d = display_q << 1;
			end

			next_state = DONE;
		end

		MEDIAN_FILTERING : begin
		end

		YCbCR : begin
		end

		CENSUS_TRANF : begin
		end

		DONE : begin
			o_op_ready_w = 1'b0;
			if (output_ctr_q < max_pixels) begin
				o_out_valid_w = 1'b1;

				case (display_q)
				    3'd4: o_out_data_w = pixels[{origin_row_q + output_ctr_q[3:2],
								  origin_col_q + output_ctr_q[1:0]}];

				    //3'd2: o_out_data_w = pixels[{origin_row_q + output_ctr_q[1]*2,
				    //				  origin_col_q + output_ctr_q[0]*2}];
					 3'd2: o_out_data_w = pixels[{origin_row_q + row_off_2,
                                 origin_col_q + col_off_2}];

				    3'd1: o_out_data_w = pixels[{origin_row_q, origin_col_q}];

				    default: o_out_data_w = 0;
				endcase

			end else begin
				o_op_ready_w = 1'b1;
				o_out_valid_w = 1'b0;
				next_state    = IDLE;
			end
		end

		default : begin
		end
	endcase
end


// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		o_op_ready_r <= 0;
		o_in_ready_r <= 0;
		o_out_valid_r <= 0;
		o_out_data_r <= 0;

		curr_state <= IDLE;
		curr_op_q <= 0;

		pixel_ctr_q <= 0;

		display_q <= 3'b100;
		image_size_q <= 5'd16;

		output_ctr_q <= 0;

		origin_row_q <= 0;
		origin_col_q <= 0;

	end else begin
		// output 
		o_op_ready_r <= o_op_ready_w;
		o_in_ready_r <= o_in_ready_w;
		o_out_valid_r <= o_out_valid_w;
		o_out_data_r <= o_out_data_w;

		curr_state <= next_state;
		curr_op_q <= curr_op_d;
		
		display_q <= display_d; // 4, 2, or 1

		// output_ctr_q <= output_ctr_d; // counting output pixels using display size.

		image_size_q <= image_size_d;  // display size, 16, 8, or 4

		origin_row_q <= origin_row_d;
		origin_col_q <= origin_col_d;

		if (i_in_valid && (curr_state == LOAD)) begin
			pixels[pixel_ctr_q] <= i_in_data;
			pixel_ctr_q <= pixel_ctr_q + 1'b1;
		end else if (curr_state != LOAD) begin
			pixel_ctr_q <= 0;
		end

		if (curr_state == DONE) begin
			// if (output_ctr_q <= max_pixels) begin
			output_ctr_q <= output_ctr_q + 1;
		end else begin
			output_ctr_q <= 0;
		end
	end

end
endmodule

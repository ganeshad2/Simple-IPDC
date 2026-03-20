
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

reg [23:0] pixels[0:255];
reg [7:0] pixel_ctr_q;

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

	o_in_ready_w = 1'b0;
	o_out_data_w = 0;
	o_out_valid_w = 0;

	case (curr_state)
		IDLE : begin
			o_op_ready_w = 1'b1;
			if ((i_op_mode == 4'b0000) && (i_op_valid == 1'b1)) begin
				next_state = LOAD;
			end
		end

		LOAD : begin
			o_op_ready_w = 1'b0;
			o_in_ready_w = 1'b1;
			if (pixel_ctr_q == 8'd255 && i_in_valid) begin
				next_state = DONE;
				o_in_ready_w = 1'b0;
			end
		end

		SHIFT : begin
		end


		SCALE : begin
		end

		MEDIAN_FILTERING : begin
		end

		YCbCR : begin
		end

		CENSUS_TRANF : begin
		end

		DONE : begin
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

		pixel_ctr_q <= 0;
		
	end else begin
		// output 
		o_op_ready_r <= o_op_ready_w;
		o_in_ready_r <= o_in_ready_w;
		o_out_valid_r <= o_out_valid_w;
		o_out_data_r <= o_out_data_w;

		curr_state <= next_state;
		
		// pixel_ctr_q <= pixel_ctr_d;

		if (i_in_valid && (curr_state == LOAD)) begin
			pixels[pixel_ctr_q] <= i_in_data;
			pixel_ctr_q <= pixel_ctr_q + 1'b1;
		end
	end

end
endmodule

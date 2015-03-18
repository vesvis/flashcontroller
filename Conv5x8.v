`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:31:15 07/14/2012 
// Design Name: 
// Module Name:    Conv5x8 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Conv5x8(
    input clk,
    input control,
	 input tx_done_tick,
	 input reset,
	 input [39:0] roout,
	 output [7:0] adout,
	 output tx_start,
	 output tx_done
    );



reg tx_start_v;
reg tx_done_v;
reg [7:0] adout_v;
reg [3:0] state;


assign tx_done = tx_done_v;
assign adout=adout_v;
assign tx_start = tx_start_v;


always @(posedge clk)
	begin
	if(reset)
		state <= 4'b0000;
	else 
		case(state)
			4'b0000: if(control) state <= 4'b0001; else state <= 4'b0000;
			4'b0001: state <= 4'b0010; 
			4'b0010: if(tx_done_tick) state <= 4'b0011; else state <= 4'b0010;
	
			4'b0011: state <= 4'b0100; 	
			4'b0100: state <= 4'b0101; 
			4'b0101: if(tx_done_tick) state <= 4'b0110; else state <= 4'b0101;

			4'b0110: state <= 4'b0111; 			
			4'b0111: state <= 4'b1000; 
			4'b1000: if(tx_done_tick) state <= 4'b1001; else state <= 4'b1000;
						
			4'b1001: state <= 4'b1010; 
			4'b1010: state <= 4'b1011; 
			4'b1011: if(tx_done_tick) state <= 4'b1100; else state <= 4'b1011;
			
			4'b1100: state <= 4'b1101; 
			4'b1101: state <= 4'b1110; 
			4'b1110: if(tx_done_tick) state <= 4'b1111; else state <= 4'b1110;
			
			4'b1111: state <= 4'b0000;
			default: state <= 4'b0000;
		endcase
	end 
			


always @ *
begin
	case (state)
	  4'b0000: begin adout_v <= roout[39:32]; tx_start_v <= 1'b0; tx_done_v <= 1'b0; end
	  4'b0001: begin adout_v <= roout[39:32]; tx_start_v <= 1'b1; tx_done_v <= 1'b0; end
	  4'b0010: begin adout_v <= roout[39:32]; tx_start_v <= 1'b0; tx_done_v <= 1'b0; end

    4'b0011: begin adout_v <= roout[31:24]; tx_start_v <= 1'b0; tx_done_v <= 1'b0; end	 
    4'b0100: begin adout_v <= roout[31:24]; tx_start_v <= 1'b1; tx_done_v <= 1'b0; end
	  4'b0101: begin adout_v <= roout[31:24]; tx_start_v <= 1'b0; tx_done_v <= 1'b0; end
    
	  4'b0110: begin adout_v <= roout[23:16];  tx_start_v <= 1'b0; tx_done_v <= 1'b0; end 
    4'b0111: begin adout_v <= roout[23:16];  tx_start_v <= 1'b1; tx_done_v <= 1'b0; end 
    4'b1000: begin adout_v <= roout[23:16];  tx_start_v <= 1'b0; tx_done_v <= 1'b0; end

    4'b1001: begin adout_v <= roout[15:8];   tx_start_v <= 1'b0; tx_done_v <= 1'b0; end	 
    4'b1010: begin adout_v <= roout[15:8];   tx_start_v <= 1'b1; tx_done_v <= 1'b0; end
	  4'b1011: begin adout_v <= roout[15:8];   tx_start_v <= 1'b0; tx_done_v <= 1'b0; end
	 
	  4'b1100: begin adout_v <= roout[7:0];   tx_start_v <= 1'b0; tx_done_v <= 1'b0; end	 
    4'b1101: begin adout_v <= roout[7:0];   tx_start_v <= 1'b1; tx_done_v <= 1'b0; end
	  4'b1110: begin adout_v <= roout[7:0];   tx_start_v <= 1'b0; tx_done_v <= 1'b0; end


	  4'b1111: begin adout_v <= 4'd0; tx_start_v <= 1'b0; tx_done_v <= 1'b1; end
	  default: begin adout_v <= 4'd0;  tx_start_v <= 1'b0; tx_done_v <= 1'b0; end
	endcase
end 

endmodule

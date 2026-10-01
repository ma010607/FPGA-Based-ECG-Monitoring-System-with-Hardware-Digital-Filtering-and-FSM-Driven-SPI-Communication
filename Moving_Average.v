`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/12 18:38:15
// Design Name: 
// Module Name: MAfilter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module MAfilter #(
    parameter IN  = 24,  
    parameter OUT = 24,  
    parameter WIN_SIZE = 64
)(
    input wire clk, rst_n,
    input wire en_250,
    input wire signed [IN-1:0] data_in,
    output reg signed [OUT-1:0] data_out
);

    integer i;
    reg signed [IN-1:0] delay [0:WIN_SIZE-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<WIN_SIZE; i=i+1) begin
                delay[i] <= 24'd0;
            end
        end
        else if (en_250) begin
            for (i=WIN_SIZE-1; i>0; i=i-1) begin
                delay[i] <= delay[i-1];
            end
            delay[0] <= data_in;
        end
    end
    
    
    reg signed [31:0] sum;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum <= 32'd0;
            data_out <= 24'd0;
        end
        else if (en_250) begin
            sum <= sum + data_in - delay[WIN_SIZE-1];
            //다음 clk 에서 나누기 
            data_out <= sum >>> 6;
        end
    end

endmodule
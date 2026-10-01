`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/08/12 10:08:13
// Design Name: 
// Module Name: Derivative
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


module Derivative #(
    parameter IN  = 12, 
    parameter OUT = 24   
)(
    input wire clk, rst_n,
    input wire en_250,
    input wire signed [IN-1:0] data_in,  
    output reg signed [OUT-1:0] data_out  
);

    integer i;
    reg signed [IN-1:0] delay [0:4];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<5; i=i+1) begin
                delay[i] <= 12'd0;
            end
        end
        else if (en_250) begin
            for (i=4; i>0; i=i-1) begin
                delay[i] <= delay[i-1];
            end
            delay[0] <= data_in;
        end
    end

    //  y[n] = x[n] + (2*x[n-1]) - (2*x[n-3]) - x[n-4] / 8
    reg signed [14:0] diff_sum;
    reg signed [11:0] diff_out; 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff_sum <= 15'd0;
            diff_out <= 12'd0;
        end
        else if (en_250) begin
            
            diff_sum <= delay[0] + (delay[1] <<< 1) - (delay[3]<<< 1) - delay[4];
           
            diff_out <= diff_sum >>> 3; 
        end
    end

   always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 24'd0;
        end
        else if (en_250) begin
            data_out <= diff_out * diff_out;
        end
    end

endmodule
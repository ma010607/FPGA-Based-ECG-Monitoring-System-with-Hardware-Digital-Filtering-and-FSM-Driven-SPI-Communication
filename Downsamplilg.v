`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/09/07 16:17:24
// Design Name: 
// Module Name: Downsampling
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


module Downsampling(
    input wire clk, rst_n,
    input wire en,
    output reg en_250
    );

reg toggle;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        toggle <= 1'b0;
        en_250 <= 1'b0;
    end
    else begin
        en_250 <= 1'b0;

        if (en) begin
            toggle <= ~toggle;

            if (toggle == 1'b0)
                en_250 <= 1'b1;
        end
    end
end
endmodule
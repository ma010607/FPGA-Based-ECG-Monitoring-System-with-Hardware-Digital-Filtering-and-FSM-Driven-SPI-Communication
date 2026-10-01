`timescale 1ns / 1ps

module ecg_top(
input clk, reset_n,
input [11:0] ecg_in,
output spi_dc, hw_rst,spi_cs, spi_sck, spi_mosi,
output wire [1:0] position,
output wire [3:0] hundreds,
output wire [3:0] tens,
output wire [3:0] units,
output wire [7:0] bpm_out,
output wire falling,
output wire [15:0] sample_counter,
input  wire valid
);

    wire w_dc;
    wire w_cs;
    wire [11:0] bcd_out ;
    wire tx_busy;
    wire [7:0] spi_data_out;
    wire start_tx;
    wire [4:0] cs_ctrl;
    wire [7:0] data_in;

    bpm a1(
    .clk(clk),
    .reset_n(reset_n),
    .ecg_in(ecg_in),
    .bpm_out(bpm_out), 
    .falling(falling),
    .sample_counter(sample_counter),
    .valid(valid)
    );


    bcd a2(
    .bpm_out(bpm_out), 
    .bcd_out(bcd_out)    
    );

    assign units    = bcd_out[3:0];
    assign tens     = bcd_out[7:4];
    assign hundreds = bcd_out[11:8];

    display_controller a3(
    .clk(clk),
    .reset_n(reset_n),
    .bcd_out(bcd_out),
    .tx_busy(tx_busy),
    .spi_data_out(spi_data_out),
    .start_tx(start_tx),
    .dc(w_dc),
    .hw_rst(hw_rst),
    .cs_ctrl(cs_ctrl),
    .position(position),
    .cs(w_cs)
    );

    spi_display a4(
    .clk(clk),
    .reset_n(reset_n),
    .data_in(spi_data_out),
    .start_tx(start_tx),
    .dc(w_dc),
    .spi_dc(spi_dc),
    .tx_busy(tx_busy),
    .spi_sck(spi_sck),
    .spi_mosi(spi_mosi),
    .spi_cs(spi_cs),
    .cs_in(w_cs)
    );
endmodule
`timescale 1ns / 1ps

module wave_top(
input clk, reset_n,
input [11:0] rx_data,
input valid,                  
output wave_dc, hwave_rst, wave_cs, wave_sck, wave_mosi
);
    
    // wave
    wire [7:0] spi_data_out;
    wire start_tx;
    wire dc;
    wire cs;
    wire [4:0] cs_ctrl;
    
    // spi_wave
    wire tx_busy;
    
    wave a3(
    .clk(clk),
    .reset_n(reset_n),
    .rx_data(rx_data),
    .valid(valid),         
    .tx_busy(tx_busy),
    .spi_data_out(spi_data_out),
    .start_tx(start_tx),
    .dc(dc),
    .hwave_rst(hwave_rst),
    .cs(cs),
    .cs_ctrl(cs_ctrl)
    );
    
    spi_wave a4(
    .clk(clk),
    .reset_n(reset_n),
    .data_in(spi_data_out),
    .start_tx(start_tx),
    .dc(dc),
    .cs_in(cs),
    .tx_busy(tx_busy),
    .wave_sck(wave_sck),
    .wave_mosi(wave_mosi),
    .wave_cs(wave_cs),
    .wave_dc(wave_dc)
    );

endmodule
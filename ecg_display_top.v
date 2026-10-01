 `timescale 1ns / 1ps
   
   module ecg_display_top(
       //system signal
       input clk, reset_n,
       //ADC
       input miso,
       output cs_n,
       output mosi,
       output sclk,
   
       //ecg top
       output spi_dc,
       output hw_rst,
       output spi_cs,
       output spi_sck,
       output spi_mosi,
       //wave_top
       output wave_dc, 
       output wave_mosi,
       output wave_cs, 
       output wave_sck, 
       output hwave_rst
       );
   
       //ECG_data
       wire [11:0] rx_data;
        (* mark_debug = "true", keep = "true" *) wire done;
       //LPF filter
        (* mark_debug = "true", keep = "true" *) wire signed [11:0] LPF_data_in;
        (* mark_debug = "true", keep = "true" *) wire signed [11:0] LPF_data_out;
       //BPF filter
         (* mark_debug = "true", keep = "true" *) wire signed [11:0] BPF_data_out;
        //Derivative
         (* mark_debug = "true", keep = "true" *) wire signed [23:0] Deriv_data_out;
        //Moving average
         (* mark_debug = "true", keep = "true" *) wire signed [23:0] MA_data_out;
        //downsampling
       wire en_250;
       //display - bpm
       wire [1:0] position;
       wire [3:0] hundreds;
       wire [3:0] tens;
       wire [3:0] units;
       (* mark_debug = "true", keep = "true" *) wire [7:0] bpm_out;
       wire falling;
       (* mark_debug = "true", keep = "true" *) wire [15:0] sample_counter;
       (* mark_debug = "true", keep = "true" *)wire [15:0] driven_counter;
       
       ECG u1(
        .clk(clk),
        .rst_n(reset_n),
        .cs_n(cs_n),
        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),    
        .rx_data(rx_data),
        .done(done),
        //LPF filter
        .LPF_data_in(LPF_data_in),
        .LPF_data_out(LPF_data_out),
        //BPF filter
        .BPF_data_out(BPF_data_out),
        //Derivative
        .Deriv_data_out(Deriv_data_out),
        //Moving average
        .MA_data_out(MA_data_out),
        //downsampling
        .en_250(en_250)
       );
   
       ecg_top u2(
       .clk(clk),
       .reset_n(reset_n),
       .ecg_in(MA_data_out),
       .spi_dc(spi_dc), 
       .hw_rst(hw_rst),
       .spi_cs(spi_cs), 
       .spi_sck(spi_sck), 
       .spi_mosi(spi_mosi),
       .position(position),
       .hundreds(hundreds),
       .tens(tens),
       .units(units),
       .bpm_out(bpm_out),
       .falling(falling),
       .sample_counter(sample_counter),
       .valid(en_250)
       );
       
       wave_top u4(
               .clk(clk), 
               .reset_n(reset_n),
               .rx_data(LPF_data_out),
               .valid(en_250),  
               .wave_dc(wave_dc), 
               .hwave_rst(hwave_rst),
               .wave_cs(wave_cs), 
               .wave_sck(wave_sck), 
               .wave_mosi(wave_mosi)
           );
      
   endmodule
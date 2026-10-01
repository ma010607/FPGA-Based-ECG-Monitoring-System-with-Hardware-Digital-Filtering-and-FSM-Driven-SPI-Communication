    module SPI_TOP(
    
        input  wire clk,       
        input  wire rst_n,     
        input  wire start,         
        output wire [11:0] rx_data,   
        output wire done,      
    
        output wire cs_n,  
        output wire sclk,     
        output wire mosi,    
        input  wire miso       
    );
        wire [4:0] cmd = 5'b11000;
        wire tx_en, rx_en;
        wire tx_done, rx_done;
        wire sclk_rise, sclk_fall;
    
        SPI_TOTAL_FSM FSM(
            .clk        (clk),
            .rst_n      (rst_n),
            .FSM_start  (start),       
            .FSM_done   (done),        
            .tx_done    (tx_done),
            .rx_done    (rx_done),
            .sclk_fall  (sclk_fall),
            .tx_en      (tx_en),
            .rx_en      (rx_en),
            .cs_n       (cs_n)         
            );
        
        SPI_sclk_gen SCLK(
            .clk(clk),
            .rst_n(rst_n),
            .en(cs_n),       
            .sclk(sclk),       
            .sclk_rise(sclk_rise),
            .sclk_fall(sclk_fall)
            );
    
        SPI_mosi MOSI(
            .clk(clk),
            .rst_n(rst_n),
            .tx_en(tx_en),
            .cmd(cmd),        
            .sclk_fall(sclk_fall),
            .mosi(mosi),       
            .tx_done(tx_done)
            );
    
        SPI_miso MISO(
            .clk(clk),
            .rst_n(rst_n),
            .rx_en(rx_en),
            .sclk_rise(sclk_rise),
            .miso(miso),       
            .rx_data(rx_data),    
            .rx_done(rx_done)
            );
    
    endmodule

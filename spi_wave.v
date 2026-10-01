`timescale 1ns / 1ps

module spi_wave (
    input clk,  reset_n,      
    input [7:0] data_in,  
    input start_tx,         
    input dc,       
    input cs_in,     
    
    output reg tx_busy,   
    output reg wave_sck,
    output reg wave_mosi,
    output     wave_cs,
    output reg wave_dc
);

    parameter IDLE      = 2'd0; 
    parameter READ_DATA = 2'd1; 
    parameter TRANSMIT  = 2'd2; 

    reg [1:0] state;
    reg [7:0] data_reg;
    reg [2:0] bit_counter;    
    reg [3:0] clk_count;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            clk_count <= 0;
            wave_sck <= 1'b0;
            data_reg <= 8'h00;
            bit_counter <= 3'd7;
            wave_mosi <= 1'b0;
            wave_dc <= 1'b1;
            tx_busy <= 1'b0;
        end
        else begin
            case (state)
                IDLE: begin
                    wave_sck <= 1'b0;
                    tx_busy <= 1'b0; 
                    clk_count <= 0;   

                    if (start_tx) begin
                        data_reg <= data_in;
                        wave_dc <= dc;   
                        state <= READ_DATA;
                        tx_busy <= 1'b1; 
                    end
                end

                READ_DATA: begin
                    bit_counter <= 3'd7;      
                    wave_mosi <= data_reg[7];  
                    state <= TRANSMIT;
                end    
                
                TRANSMIT: begin
                    clk_count <= clk_count + 1'b1;
                    if (clk_count == 4'd3) begin
                        wave_sck <= ~wave_sck;
                        clk_count <= 0;
                        
                        if (wave_sck == 1'b1) begin
                            if (bit_counter != 3'd0) begin
                                data_reg <= {data_reg[6:0], 1'b0}; 
                                bit_counter <= bit_counter - 1'b1;
                                wave_mosi <= data_reg[6];
                            end
                            else begin
                                state <= IDLE;
                                tx_busy <= 1'b0;
                                wave_sck <= 1'b0;
                                wave_mosi <= 1'b0;
                            end
                        end
                    end
                end
            endcase
        end
    end
    
    assign wave_cs = cs_in;
endmodule
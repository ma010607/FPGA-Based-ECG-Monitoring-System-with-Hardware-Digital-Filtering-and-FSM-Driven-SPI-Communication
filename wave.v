`timescale 1ns / 1ps

module wave(
    input clk, reset_n,
    input [11:0] rx_data,       
    input tx_busy,           
    input valid,                    
   
    output reg [7:0] spi_data_out,
    output reg start_tx, dc, hwave_rst, cs,
    output reg [4:0] cs_ctrl
);

    parameter D_INIT     = 3'd0;
    parameter BLACK_POS  = 3'd1;
    parameter D_BLACK    = 3'd2;
    parameter D_IDLE     = 3'd3;
    parameter D_POSITION = 3'd4;
    parameter D_DRAW     = 3'd5;
            
    reg [2:0]  state;
    reg [31:0] timer;
    
    reg [7:0]  x_position;        
    reg [7:0]  y_position;        

    reg [7:0]  offset_reg;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            offset_reg <= 8'd0;
            y_position <= 8'd64; 
        end else if (valid) begin
            if (rx_data >= 12'd2048) begin
                offset_reg <= (rx_data - 12'd2048) >> 5; 
                
                if (((rx_data - 12'd2048) >> 5) > 60) begin
                    y_position <= 8'd4;
                end else begin
                    y_position <= 8'd64 - ((rx_data - 12'd2048) >> 5);
                end
            end 
            else begin
                offset_reg <= (12'd2048 - rx_data) >> 5;
                
                if (((12'd2048 - rx_data) >> 5) > 60) begin
                    y_position <= 8'd124;
                end else begin
                    y_position <= 8'd64 + ((12'd2048 - rx_data) >> 5);
                end
            end
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            state        <= D_INIT;
            timer        <= 0;
            spi_data_out <= 0;
            start_tx     <= 0;
            cs_ctrl      <= 0;
            dc           <= 0;
            hwave_rst    <= 1'b1;
            cs           <= 1;
            x_position   <= 8'h5;   
        end
        else begin
            start_tx <= 0;
                    
            case(state)
                D_INIT: begin  
                    if(!tx_busy && !start_tx) begin
                        case(cs_ctrl)
                            0: begin spi_data_out <= 8'h00; hwave_rst <= 1'b0; timer <= 0; cs_ctrl <= 1; end
                            1: begin if(timer >= 32'd10_000_000) begin hwave_rst <= 1'b1; timer <= 0; cs_ctrl <= 2; end else timer <= timer + 1; end
                            2: begin if(timer >= 32'd15_000_000) begin timer <= 0; cs_ctrl <= 3; end else timer <= timer + 1; end
                            3: begin dc <= 1'b0; spi_data_out <= 8'h01; start_tx <= 1'b1; timer <= 0; cs_ctrl <= 4; cs <= 0; end
                            4: begin cs <= 1; cs_ctrl <= 5; end
                            5: begin if(timer >= 32'd15_000_000) begin timer <= 0; cs_ctrl <= 6; cs <= 0; end else timer <= timer + 1; end
                            6: begin dc <= 1'b0; spi_data_out <= 8'h11; start_tx <= 1'b1; timer <= 0; cs_ctrl <= 7; cs <= 0; end
                            7: begin cs <= 1; cs_ctrl <= 8; end
                            8: begin if(timer >= 32'd15_000_000) begin timer <= 0; cs_ctrl <= 11; end else timer <= timer + 1; end
                            11: begin dc <= 1'b0; spi_data_out <= 8'h3A; start_tx <= 1'b1; cs_ctrl <= 12; cs <= 0; end
                            12: begin dc <= 1'b1; spi_data_out <= 8'h55; start_tx <= 1'b1; cs_ctrl <= 9; cs <= 0; end
                            9: begin dc <= 1'b0; spi_data_out <= 8'h36; start_tx <= 1'b1; cs_ctrl <= 10; cs <= 0; end
                            10: begin dc <= 1'b1; spi_data_out <= 8'h68; start_tx <= 1'b1; cs_ctrl <= 13; end
                            13: begin  
                                dc <= 1'b0; spi_data_out <= 8'h29; start_tx <= 1'b1; timer <= 0; 
                                cs_ctrl <= 0;        
                                state <= BLACK_POS; 
                            end
                            default: cs_ctrl <= 0;
                        endcase
                    end
                end
                
                BLACK_POS: begin
                    if (!tx_busy && !start_tx) begin
                        cs <= 0;
                        case(cs_ctrl)
                            0: begin dc <= 0; spi_data_out <= 8'h2A; start_tx <= 1; cs_ctrl <= 1; end 
                            1: begin dc <= 1; spi_data_out <= 8'h00; start_tx <= 1; cs_ctrl <= 2; end 
                            2: begin dc <= 1; spi_data_out <= 8'h00; start_tx <= 1; cs_ctrl <= 3; end 
                            3: begin dc <= 1; spi_data_out <= 8'h00; start_tx <= 1; cs_ctrl <= 4; end 
                            4: begin dc <= 1; spi_data_out <= 8'h9F; start_tx <= 1; cs_ctrl <= 5; end 
                            5: begin dc <= 0; spi_data_out <= 8'h2B; start_tx <= 1; cs_ctrl <= 6; end
                            6: begin dc <= 1; spi_data_out <= 8'h00; start_tx <= 1; cs_ctrl <= 7; end 
                            7: begin dc <= 1; spi_data_out <= 8'h00; start_tx <= 1; cs_ctrl <= 8; end 
                            8: begin dc <= 1; spi_data_out <= 8'h00; start_tx <= 1; cs_ctrl <= 9; end 
                            9: begin dc <= 1; spi_data_out <= 8'h7F; start_tx <= 1; cs_ctrl <= 10; end 
                            10: begin  
                                dc <= 0; spi_data_out <= 8'h2C; start_tx <= 1; timer <= 0;
                                cs_ctrl <= 0;        
                                state <= D_BLACK;
                                x_position <= 8'h5; 
                            end
                            default: cs_ctrl <= 0;
                        endcase
                    end
                end
        
                D_BLACK: begin
                    if (!tx_busy && !start_tx) begin
                        cs <= 0;
                        case(cs_ctrl)
                            0: begin dc <= 1; spi_data_out <= 8'h00; start_tx <= 1; cs_ctrl <= 1; end
                            1: begin
                                dc <= 1; spi_data_out <= 8'h00; start_tx <= 1; cs_ctrl <= 0; 
                                
                                if (timer < 32'd40959) begin 
                                    timer <= timer + 1;
                                end
                                else begin 
                                    timer <= 0; cs <= 1; 
                                    cs_ctrl <= 0;    
                                    state <= D_IDLE; 
                                end
                            end
                            default: cs_ctrl <= 0;
                        endcase
                    end
                end
        
               D_IDLE: begin
    start_tx     <= 1'b0;
    cs           <= 1'b1;
    spi_data_out <= 8'h00;

    if (valid) begin
        if (cs_ctrl == 5'd0) begin
            cs_ctrl <= 5'd1;      // 첫 번째 valid: 낡은 y_position 버리고 대기만 함
        end
        else begin
            cs_ctrl <= 5'd0;      // 두 번째 valid부터 정식으로 그리기 시작
            state   <= D_POSITION;
        end
    end
    else begin
        cs_ctrl <= cs_ctrl;       // valid 없으면 그대로 유지
    end
end
        
                D_POSITION: begin
                    if (!tx_busy && !start_tx) begin
                        cs <= 0; 
                        case(cs_ctrl)
                            0: begin dc <= 0; spi_data_out <= 8'h2A; start_tx <= 1; cs_ctrl <= 1; end 
                            1: begin dc <= 1; spi_data_out <= 8'h00; start_tx <= 1; cs_ctrl <= 2; end 
                            2: begin dc <= 1; spi_data_out <= x_position; start_tx <= 1; cs_ctrl <= 3; end 
                            3: begin dc <= 1; spi_data_out <= 8'h00; start_tx <= 1; cs_ctrl <= 4; end 
                            4: begin dc <= 1; spi_data_out <= x_position + 3; start_tx <= 1; cs_ctrl <= 5; end 
                            
                            5: begin dc <= 0; spi_data_out <= 8'h2B; start_tx <= 1; cs_ctrl <= 6; end
                            6: begin dc <= 1; spi_data_out <= 8'h00; start_tx <= 1; cs_ctrl <= 7; end 
                            7: begin dc <= 1; spi_data_out <= y_position; start_tx <= 1; cs_ctrl <= 8; end 
                            8: begin dc <= 1; spi_data_out <= 8'h00; start_tx <= 1; cs_ctrl <= 9; end 
                            9: begin dc <= 1; spi_data_out <= y_position + 3; start_tx <= 1; cs_ctrl <= 11; end 
                            
                            11: begin 
                                dc           <= 0; 
                                spi_data_out <= 8'h2C; 
                                start_tx     <= 1;
                                state        <= D_DRAW;
                                timer        <= 0; 
                                cs_ctrl      <= 0;   
                            end
                            default: cs_ctrl <= 0;
                        endcase
                    end
                end
        
                D_DRAW: begin
                    if (!tx_busy && !start_tx) begin
                        case(cs_ctrl)
                            0: begin dc <= 1; cs <= 0; spi_data_out <= 8'h00; start_tx <= 1; cs_ctrl <= 1; end
                            1: begin dc <= 1;          spi_data_out <= 8'h1F; start_tx <= 1; cs_ctrl <= 2; end
                            
                            2: begin 
                                if (timer < 15) begin 
                                    timer <= timer + 1;
                                    cs_ctrl <= 0;
                                end else begin
                                    timer    <= 0;
                                    start_tx <= 1'b0;
                                    cs       <= 1'b1;
                                    state    <= D_IDLE; 
                                    cs_ctrl  <= 0;
                                    
                                    if (x_position < 159) begin
                                        x_position <= x_position + 2'd2; 
                                    end
                                    else begin
                                        x_position <= 8'h5;         
                                        cs_ctrl    <= 0; 
                                        state      <= BLACK_POS;   
                                    end
                                end
                            end
                            default: cs_ctrl <= 0;
                        endcase
                    end
                end
            endcase
        end
    end
endmodule
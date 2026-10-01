module SPI_mosi(
    input wire clk,
    input wire rst_n,
    input wire tx_en,    //cs_active low
    input wire [4:0] cmd,
    
    input wire sclk_fall,
    
    output reg mosi,
    output reg tx_done
  );
    reg tx_busy;
    reg [4:0] shift_reg;
    reg [2:0] cmd_cnt;
    
    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mosi <= 1'b0;
            tx_done <= 1'b0;
            tx_busy <= 1'b0;
            shift_reg <= 5'b0;
            cmd_cnt <= 3'b0;
        end else begin
            tx_done <= 1'b0;
            if (tx_en && !tx_busy) begin
                shift_reg <= cmd;
                mosi <= cmd[4];
                cmd_cnt <= 3'd0;
                tx_busy <= 1'b1;
            end else if (tx_busy && sclk_fall) begin
                    if (cmd_cnt == 3'd4) begin
                        cmd_cnt <= 3'b0;
                        tx_busy <= 1'b0;
                        tx_done <= 1'b1;
                    end else begin     
                        shift_reg <= {shift_reg[3:0], 1'b0};
                        mosi <= shift_reg[3];
                        cmd_cnt <= cmd_cnt + 1'b1;
                    end
                end
            end
        end  
endmodule
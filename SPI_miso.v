module SPI_miso(
    input wire clk,
    input wire rst_n,
    input wire rx_en,
    input wire sclk_rise, 
    
    input wire miso,

    output reg [11:0] rx_data,
    output reg rx_done
    );
    reg rx_busy;
    reg [12:0] shift_reg;
    reg [3:0] data_cnt;
    
    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_data <= 12'd0;
            rx_done <= 1'b0;
            rx_busy <= 1'b0;
            shift_reg <= 13'd0;
            data_cnt <= 4'd0;
        end else begin
            rx_done <= 1'b0;
            if (rx_en && !rx_busy) begin
                shift_reg <= 13'd0;
                data_cnt <= 4'd0;
                rx_busy <= 1'b1;
            end else if (rx_busy && sclk_rise) begin
                    if (data_cnt == 4'd12) begin
                        data_cnt <= 4'd0;
                        rx_busy <= 1'b0;
                        rx_data <= {shift_reg[10:0], miso};
                        rx_done <= 1'b1;
                    end else begin
                        shift_reg <= {shift_reg[11:0], miso};
                        data_cnt <= data_cnt + 1'b1;
                    end
                end
            end
        end
endmodule
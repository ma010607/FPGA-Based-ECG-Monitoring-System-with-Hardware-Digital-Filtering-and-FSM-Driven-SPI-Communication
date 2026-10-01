module SPI_sclk_gen (
    input wire clk,         
    input wire rst_n,
    input wire en,      //cs 신호에 맞춰서 동작
    output reg sclk,        
    output wire sclk_rise, 
    output wire sclk_fall  
    );
    reg [5:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 6'd0;
            sclk <= 1'b0;  
        end else begin
            if (!en) begin
                if (counter == 6'd49) begin
                    counter <= 6'd0;
                    sclk <= ~sclk; 
                end else begin
                    counter <= counter + 1'b1;
                end
            end else begin
                counter <= 6'd0;
                sclk <= 1'b0;
            end
        end
    end
    assign sclk_rise = (counter == 6'd49) && (sclk == 1'b0);
    assign sclk_fall = (counter == 6'd49) && (sclk == 1'b1);

endmodule
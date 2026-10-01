module bpm (
    input  clk,
    input  reset_n,
    input  signed [23:0] ecg_in,
    input  valid,
    output wire falling,
    output reg [15:0] sample_counter,
    output reg [7:0] bpm_out,
    output reg [15:0] driven_counter
);
    //timing
    reg [15:0] save_reg;
    reg [15:0] driven_reg;
    
    reg div_start;
    reg div_busy;
    
    parameter PEAK = 12'd400; 
    reg peak_now;
    reg peak_before;
 
    assign falling = peak_before && !peak_now;
    
    always @(posedge clk) begin
        if (ecg_in >= PEAK) begin
            peak_now = 1'b1;
        end
        else begin
            peak_now = 1'b0;
        end
    end


    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            peak_before    <= 1'b0;
            sample_counter <= 16'd0;
            save_reg <= 16'd0;
            div_start <= 1'b0;
        end
        else begin
            div_start <= 1'b0;
            
            if (valid) begin
                peak_before <= peak_now; 

                if (falling) begin
                    if ((sample_counter > 0) && !div_busy) begin
                        save_reg <= sample_counter; 
                        div_start <= 1'b1;
                    end
                    sample_counter <= 16'd0;
                end
                else 
                sample_counter <= sample_counter + 1'b1;
            end
        end
    end
    
    always@(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            driven_reg <= 16'd0;
            driven_counter <= 16'd0;
            div_busy <= 1'b0;
            bpm_out <= 8'd0;
        end
        else begin
            if (div_start && !div_busy) begin
                driven_reg <= 16'd15000;
                driven_counter <= 16'd0;
                div_busy <= 1'b1;
            end
            else if (div_busy) begin
                if (driven_reg >= save_reg) begin
                    driven_reg <= driven_reg - save_reg;
                    driven_counter <= driven_counter + 1'b1;
                end
                else begin
                    div_busy <= 1'b0;
                    if (driven_counter > 16'd255)
                        bpm_out <= 8'd255;
                    else
                        bpm_out <= driven_counter[7:0];
                end
            end
        end
    end       
endmodule
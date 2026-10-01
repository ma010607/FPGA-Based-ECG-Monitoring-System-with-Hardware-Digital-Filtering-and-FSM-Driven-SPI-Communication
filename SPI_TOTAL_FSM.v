module SPI_TOTAL_FSM(
    //system control signal
    input wire clk,
    input wire rst_n,
    input wire FSM_start,
    output reg FSM_done,
    //module signal
    input wire tx_done,
    input wire rx_done,
    input wire sclk_fall,
    output reg tx_en,
    output reg rx_en,
    //spi
    output reg cs_n
    );
    reg [7:0] clk_cnt;
    reg [1:0] sclk_cnt;
    reg [2:0]state;
        localparam IDLE = 3'd0;
        localparam SETUP = 3'd1;
        localparam TX_CMD = 3'd2;
        localparam SAMPLING = 3'd3;
        localparam RX_DATA = 3'd4;
        localparam WAIT_RX = 3'd5;
        localparam FINISH = 3'd6;
        localparam REST = 3'd7;
   
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            cs_n    <= 1'b1;
            tx_en     <= 1'b0;
            rx_en     <= 1'b0;
            FSM_done <= 1'b0;
            sclk_cnt  <= 2'd0;
            clk_cnt   <= 8'd0;
        end else begin
            tx_en     <= 1'b0;
            rx_en     <= 1'b0;
            FSM_done <= 1'b0;

            case (state)
                IDLE: begin
                    cs_n <= 1'b1;
                    if (FSM_start) begin
                        state <= SETUP;
                    end
                end

                // tSUCS : cs_n low 이후 100ns 기다려야함
                SETUP: begin
                    cs_n  <= 1'b0;
                    clk_cnt <= clk_cnt + 1'b1;
                    if (clk_cnt == 8'd20) begin 
                        clk_cnt <= 8'd0;
                        tx_en <= 1'b1;
                        state   <= TX_CMD;
                    end
                end

                TX_CMD: begin
                    if (tx_done)
                    state <= SAMPLING;
                end

                // tSAMPLE : D[0] ~ 대략 1.5클럭 대기 (여유롭게 2클럭)
                SAMPLING: begin
                        if (sclk_fall) begin
                                state    <= RX_DATA;
                        end
                    end

                RX_DATA: begin
                    rx_en <= 1'b1;
                    state <= WAIT_RX;
                end
                
                WAIT_RX : begin
                    if (rx_done) 
                        state <= FINISH;
                end

                FINISH: begin
                    cs_n <= 1'b1;
                    state  <= REST;
                end

                // tCSH: 다음 CMD 받기까지의 여유 시간
                REST: begin
                    clk_cnt <= clk_cnt + 1'b1;
                    if (clk_cnt == 8'd125) begin // 1us 대기 (데이터시트 최소 500ns)
                        clk_cnt   <= 8'd0;
                        FSM_done <= 1'b1;
                        state     <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
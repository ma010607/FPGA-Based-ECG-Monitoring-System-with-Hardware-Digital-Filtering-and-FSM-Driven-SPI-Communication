`timescale 1ns / 1ps

module display_controller(
    input clk, reset_n,
    input [11:0] bcd_out,       // bcd모듈의 결과를 그대로 사용
    input spi_busy,               //spi 모듈의 신로 그대로 사용  
    
    output reg [15:0] spi_data_out,
    output reg start_tx, dc
);

    //  폰트 만들기
    function [7:0] font;
        input [3:0] num; // 숫자 0~9
        input [3:0] row; // 0~15번째 줄
        begin
            case(num)
                4'd0: case(row) // 숫자 0
                    0,15:    font = 8'b00111100;
                    default: font = 8'b01000010;
                endcase
                
                4'd1: case(row) // 숫자 1
                    0,1:     font = 8'b00011000;
                    15:      font = 8'b01111110;
                    2:       font = 8'b00111000;
                    default: font = 8'b00011000;
                endcase

                4'd2: case(row) // 숫자 2
                    0,7,15:          font = 8'b01111110;
                    1,2,3,4,5,6:     font = 8'b00000010;
                    default:          font = 8'b01000000;
                endcase

                4'd3: case(row) // 숫자 3
                    0,7,15:  font = 8'b01111110;
                    default: font = 8'b00000010;
                endcase

                4'd4: case(row) // 숫자 4
                    7:       font = 8'b01111110;
                    default: font = (row < 7) ? 8'b01000010 : 8'b00000010;
                endcase

                4'd5: case(row) // 숫자 5
                    0,7,15:          font = 8'b01111110;
                    1,2,3,4,5,6:     font = 8'b01000000;
                    default:          font = 8'b00000010;
                endcase

                4'd6: case(row) // 숫자 6
                    0,7,15:          font = 8'b01111110;
                    1,2,3,4,5,6:     font = 8'b01000000;
                    default:          font = 8'b01000010;
                endcase

                4'd7: case(row) // 숫자 7
                    0:       font = 8'b01111110;
                    1,2,3:   font = 8'b00000010;
                    default: font = 8'b00010000;
                endcase

                4'd8: case(row) // 숫자 8
                    0,7,15:  font = 8'b01111110;
                    default: font = 8'b01000010;
                endcase

                4'd9: case(row) // 숫자 9
                    0,7,15:          font = 8'b01111110;
                    1,2,3,4,5,6:     font = 8'b01000010;
                    default:          font = 8'b00000010;
                endcase
                
                default: font = 8'b00000000; //디폴트값
            endcase
        end
    endfunction
    
    //상태정의
    parameter D_IDLE = 2'd0;
    parameter D_POSITION = 2'd1;
    parameter D_DRAW = 2'd2;
    
    //register
    reg [1:0] state;
    reg [1:0] position; //100 10 1의 자리 숫자
    reg [7:0] x_position;
    reg [7:0] y_position;
    reg [31:0] timer;
    reg [3:0] cs_ctrl;
    reg [3:0] num;
    reg [3:0] row_cnt;
    reg [2:0] bit_cnt;
    
   
    reg [4:0] row_counter; // 0~15
    reg [3:0] bit_counter; //0~7
    
    // 표시할 자리수 
    always@(*) begin
    if(position == 0)
    num = bcd_out[3:0]; //1의자리
    else if(position == 1)
    num = bcd_out[7:4]; //10의자리
    else
    num = bcd_out[11:8]; //100의자리
    end
    
    //x좌표 선택
     always@(*) begin
     
     y_position = 8'd140;  //y축은 고정
     case(position)
     3'd0:
     x_position = 8'd130;  // 1의자리
     
     3'd1:
     x_position = 8'd120;  //10의자리
     
     3'd2:
     x_position = 8'd110;  //100의자리
     
     default:
     x_position = 8'd110;
     endcase
   
    end
    
    
    //FSM
    always @(posedge clk or negedge reset_n)
     begin
    if(~reset_n) 
    begin
     state <= 2'd0;
     timer <= 0;
     position <=0;
     spi_data_out <=0;
     start_tx <= 0;
     cs_ctrl <= 0;
     row_cnt <= 0;
     bit_cnt <= 0;
     row_counter <= 0;
     bit_counter <= 0;
     end
    else begin
    start_tx <=0;
    
    case(state)
    D_IDLE: begin
        if(timer >= 32'd50000000)//0.5초 대기
        begin
        timer <= 0;
        position <= 0;
        state <= 2'd1;
        end
        else begin
        timer <= timer +1;
        end
    end
    
    D_POSITION: begin
    if(!spi_busy && !start_tx) begin
    start_tx <= 1;
    case(cs_ctrl)
    
    //x축
    0: 
    begin 
    dc<= 0; spi_data_out <= 16'h002A; 
    end // x축 설정 커맨드
    
    1: 
    begin 
    dc<= 1; 
    spi_data_out <= {8'd0, x_position}; //x축의 시작 위치 번호 전송
    end 
    
    2: 
    begin dc <=1; 
    spi_data_out <= {8'd0, x_position + 7}; //x축 끝좌표 전송
    end
    
    //y축
    3: 
    begin dc<=0;
    spi_data_out <= 16'h002B; //y축 설정 명령
    end //
    
    4: begin dc<= 1;
    spi_data_out <= {8'd0, y_position}; 
    end //y축의 시작 위치 번호
    
    5: 
    begin 
    dc <=1;
    spi_data_out<={8'd0, y_position + 15}; 
    end   //y축의 끝 위치 번호
    
    //다음 상태로
    6: begin 
                dc<=0; 
                cs_ctrl <=0;
                spi_data_out<=16'h002C;  // 데이터 전송
                state <= D_DRAW;
    
    end 
   
    endcase
   
    end
    end

    D_DRAW: begin
        if(!spi_busy && !start_tx) begin
            if ( font(num, row_cnt) [7 - bit_cnt] ) 
            begin
                // 폰트가 1이면 빨간색 전송
                start_tx <= 1;
                dc <= 1;
                spi_data_out <= 16'hF800; 
            end 
            
            if (row_counter < 15)
            begin
            row_counter <= row_counter + 1;
            end
            else begin
            row_counter <= 0;
            end 
            
            
            if(bit_counter < 7)
            begin
            bit_counter <= bit_counter + 1;
            end
            else begin
            bit_counter <= 0;
            end
        end
    end
    
    endcase
    end
    end
    
    
endmodule
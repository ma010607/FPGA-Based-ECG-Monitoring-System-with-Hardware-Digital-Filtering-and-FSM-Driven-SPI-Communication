module bcd (
    input  wire [11:0] bpm_out,
    output reg  [11:0] bcd_out
);
    integer i;
    reg [23:0] temp; // [11:0] 데이터 + [11:0] BCD 결과

    always @(*) begin
        temp = 0;
        temp[11:0] = bpm_out;
        
        for (i = 0; i < 12; i = i + 1) begin
            // 5보다 크면 3을 더함
            if (temp[15:12] >= 5) temp[15:12] = temp[15:12] + 3;
            if (temp[19:16] >= 5) temp[19:16] = temp[19:16] + 3;
            if (temp[23:20] >= 5) temp[23:20] = temp[23:20] + 3;
            
            temp = temp << 1;
        end
        bcd_out = temp[23:12];
    end
endmodule
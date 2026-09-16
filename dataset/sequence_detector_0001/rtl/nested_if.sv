module sequence_detector_0001_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire bit_in,
    output wire seen1,
    output wire seen10,
    output wire seen101,
    output wire match
);
    localparam [2:0] S_S0     = 3'd0;
    localparam [2:0] S_S1     = 3'd1;
    localparam [2:0] S_S10    = 3'd2;
    localparam [2:0] S_S101   = 3'd3;
    localparam [2:0] S_MATCH  = 3'd4;

    reg [2:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_S0;
        end else begin
            if (state == S_S0) begin
                state <= (bit_in) ? S_S1 : ((!bit_in) ? S_S0 : (S_S0));
            end
            else if (state == S_S1) begin
                state <= (bit_in) ? S_S1 : ((!bit_in) ? S_S10 : (S_S1));
            end
            else if (state == S_S10) begin
                state <= (bit_in) ? S_S101 : ((!bit_in) ? S_S0 : (S_S10));
            end
            else if (state == S_S101) begin
                state <= (bit_in) ? S_MATCH : ((!bit_in) ? S_S10 : (S_S101));
            end
            else if (state == S_MATCH) begin
                state <= (bit_in) ? S_S1 : ((!bit_in) ? S_S10 : (S_MATCH));
            end
            else begin
                state <= S_S0;
            end
        end
    end

    assign seen1 = (state == S_S1);
    assign seen10 = (state == S_S10);
    assign seen101 = (state == S_S101);
    assign match = (state == S_MATCH);
endmodule

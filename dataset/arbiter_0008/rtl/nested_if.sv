module arbiter_0008_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire req0,
    input  wire req1,
    input  wire req2,
    output wire grant0,
    output wire grant1,
    output wire grant2
);
    localparam [1:0] S_IDLE   = 2'd0;
    localparam [1:0] S_G0     = 2'd1;
    localparam [1:0] S_G1     = 2'd2;
    localparam [1:0] S_G2     = 2'd3;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (req0) ? S_G0 : ((!req0 && req1) ? S_G1 : ((!req0 && !req1 && req2) ? S_G2 : ((!req0 && !req1 && !req2) ? S_IDLE : (S_IDLE))));
            end
            else if (state == S_G0) begin
                state <= S_IDLE;
            end
            else if (state == S_G1) begin
                state <= S_IDLE;
            end
            else if (state == S_G2) begin
                state <= S_IDLE;
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign grant0 = (state == S_G0);
    assign grant1 = (state == S_G1);
    assign grant2 = (state == S_G2);
endmodule

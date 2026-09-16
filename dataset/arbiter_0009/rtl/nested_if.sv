module arbiter_0009_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire req0,
    input  wire req1,
    input  wire lock,
    output wire grant0,
    output wire grant1
);
    localparam [1:0] S_IDLE   = 2'd0;
    localparam [1:0] S_G0     = 2'd1;
    localparam [1:0] S_G1     = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (req1) ? S_G1 : ((!req1 && req0) ? S_G0 : ((!req1 && !req0) ? S_IDLE : (S_IDLE)));
            end
            else if (state == S_G0) begin
                state <= (lock) ? S_G0 : ((!lock) ? S_IDLE : (S_G0));
            end
            else if (state == S_G1) begin
                state <= (lock) ? S_G1 : ((!lock) ? S_IDLE : (S_G1));
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign grant0 = (state == S_G0);
    assign grant1 = (state == S_G1);
endmodule

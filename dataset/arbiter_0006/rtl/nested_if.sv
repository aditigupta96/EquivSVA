module arbiter_0006_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire req0,
    input  wire req1,
    input  wire release,
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
                state <= (req0) ? S_G0 : ((!req0 && req1) ? S_G1 : ((!req0 && !req1) ? S_IDLE : (S_IDLE)));
            end
            else if (state == S_G0) begin
                state <= (release) ? S_IDLE : ((!release) ? S_G0 : (S_G0));
            end
            else if (state == S_G1) begin
                state <= (release) ? S_IDLE : ((!release) ? S_G1 : (S_G1));
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign grant0 = (state == S_G0);
    assign grant1 = (state == S_G1);
endmodule

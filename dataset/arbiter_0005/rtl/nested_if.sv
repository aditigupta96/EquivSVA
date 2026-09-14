module arbiter_0005_nested_if (
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
    localparam [1:0] S_GRANT0 = 2'd1;
    localparam [1:0] S_GRANT1 = 2'd2;
    localparam [1:0] S_GRANT2 = 2'd3;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (req0) ? S_GRANT0 : ((req1) ? S_GRANT1 : ((req2) ? S_GRANT2 : (S_IDLE)));
            end
            else if (state == S_GRANT0) begin
                state <= S_IDLE;
            end
            else if (state == S_GRANT1) begin
                state <= S_IDLE;
            end
            else if (state == S_GRANT2) begin
                state <= S_IDLE;
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign grant0 = (state == S_GRANT0);
    assign grant1 = (state == S_GRANT1);
    assign grant2 = (state == S_GRANT2);
endmodule

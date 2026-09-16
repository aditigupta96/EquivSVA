module rate_limiter_0010_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire violation,
    input  wire clear,
    output wire clean,
    output wire strike1,
    output wire strike2,
    output wire blocked
);
    localparam [1:0] S_CLEAN  = 2'd0;
    localparam [1:0] S_S1     = 2'd1;
    localparam [1:0] S_S2     = 2'd2;
    localparam [1:0] S_BLOCKED = 2'd3;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_CLEAN;
        end else begin
            if (state == S_CLEAN) begin
                state <= (violation) ? S_S1 : ((!violation) ? S_CLEAN : (S_CLEAN));
            end
            else if (state == S_S1) begin
                state <= (violation) ? S_S2 : ((!violation) ? S_CLEAN : (S_S1));
            end
            else if (state == S_S2) begin
                state <= (violation) ? S_BLOCKED : ((!violation) ? S_CLEAN : (S_S2));
            end
            else if (state == S_BLOCKED) begin
                state <= (clear) ? S_CLEAN : ((!clear) ? S_BLOCKED : (S_BLOCKED));
            end
            else begin
                state <= S_CLEAN;
            end
        end
    end

    assign clean = (state == S_CLEAN);
    assign strike1 = (state == S_S1);
    assign strike2 = (state == S_S2);
    assign blocked = (state == S_BLOCKED);
endmodule

module rate_limiter_0003_mutant_drop_first_rule (
    input  wire clk,
    input  wire rst,
    input  wire refill,
    input  wire consume,
    output reg  [2:0] tokens,
    output wire allow,
    output wire full
);

    always @(posedge clk) begin
        if (rst) begin
            tokens <= 3'd4;
        end
        else begin
            if (!consume && refill && (tokens < 3'd7)) tokens <= tokens + 3'd1;
            else tokens <= tokens;
        end
    end

    assign allow = tokens != 3'd0;
    assign full = tokens == 3'd7;
endmodule

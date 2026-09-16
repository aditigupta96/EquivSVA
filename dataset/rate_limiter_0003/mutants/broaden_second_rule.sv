module rate_limiter_0003_mutant_broaden_second_rule (
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
            if (consume && (tokens > 3'd0)) tokens <= tokens - 3'd1;
            else tokens <= tokens + 3'd1;
        end
    end

    assign allow = tokens != 3'd0;
    assign full = tokens == 3'd7;
endmodule

module rate_limiter_0009_mutant_broaden_second_rule (
    input  wire clk,
    input  wire rst,
    input  wire admit,
    input  wire return_token,
    output reg  [2:0] tokens,
    output wire allow
);

    always @(posedge clk) begin
        if (rst) begin
            tokens <= 3'd3;
        end
        else begin
            if (return_token && (tokens < 3'd7)) tokens <= tokens + 3'd1;
            else tokens <= tokens - 3'd1;
        end
    end

    assign allow = tokens != 3'd0;
endmodule

module rate_limiter_0001_function_update (
    input  wire clk,
    input  wire rst,
    input  wire refill,
    input  wire consume,
    output reg  [2:0] tokens,
    output wire allow,
    output wire full
);

    function automatic [2:0] compute_next_tokens;
        input [2:0] current;
        input refill;
        input consume;
        begin
            if (refill && (current < 3'd7)) compute_next_tokens = current + 3'd1;
            else if (!refill && consume && (current > 3'd0)) compute_next_tokens = current - 3'd1;
            else compute_next_tokens = current;
        end
    endfunction

    wire [2:0] next_tokens;

    assign next_tokens = compute_next_tokens(tokens, refill, consume);

    always @(posedge clk) begin
        if (rst)
            tokens <= 3'd0;
        else
            tokens <= next_tokens;
    end

    assign allow = tokens != 3'd0;
    assign full = tokens == 3'd7;
endmodule

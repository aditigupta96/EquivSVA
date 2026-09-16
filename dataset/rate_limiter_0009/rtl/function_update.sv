module rate_limiter_0009_function_update (
    input  wire clk,
    input  wire rst,
    input  wire admit,
    input  wire return_token,
    output reg  [2:0] tokens,
    output wire allow
);

    function automatic [2:0] compute_next_tokens;
        input [2:0] current;
        input admit;
        input return_token;
        begin
            if (return_token && (current < 3'd7)) compute_next_tokens = current + 3'd1;
            else if (!return_token && admit && (current > 3'd0)) compute_next_tokens = current - 3'd1;
            else compute_next_tokens = current;
        end
    endfunction

    wire [2:0] next_tokens;

    assign next_tokens = compute_next_tokens(tokens, admit, return_token);

    always @(posedge clk) begin
        if (rst)
            tokens <= 3'd3;
        else
            tokens <= next_tokens;
    end

    assign allow = tokens != 3'd0;
endmodule

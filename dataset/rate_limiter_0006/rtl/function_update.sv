module rate_limiter_0006_function_update (
    input  wire clk,
    input  wire rst,
    input  wire use,
    input  wire reset_quota,
    output reg  [2:0] quota,
    output wire allow
);

    function automatic [2:0] compute_next_quota;
        input [2:0] current;
        input use;
        input reset_quota;
        begin
            if (reset_quota) compute_next_quota = 3'd5;
            else if (!reset_quota && use && (current > 3'd0)) compute_next_quota = current - 3'd1;
            else compute_next_quota = current;
        end
    endfunction

    wire [2:0] next_quota;

    assign next_quota = compute_next_quota(quota, use, reset_quota);

    always @(posedge clk) begin
        if (rst)
            quota <= 3'd5;
        else
            quota <= next_quota;
    end

    assign allow = quota != 3'd0;
endmodule

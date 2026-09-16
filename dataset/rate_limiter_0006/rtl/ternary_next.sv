module rate_limiter_0006_ternary_next (
    input  wire clk,
    input  wire rst,
    input  wire use,
    input  wire reset_quota,
    output reg  [2:0] quota,
    output wire allow
);

    wire [2:0] next_quota;

    assign next_quota = (reset_quota) ? (3'd5) : ((!reset_quota && use && (quota > 3'd0)) ? (quota - 3'd1) : (quota));

    always @(posedge clk) begin
        if (rst)
            quota <= 3'd5;
        else
            quota <= next_quota;
    end

    assign allow = quota != 3'd0;
endmodule

module rate_limiter_0006_canonical_next (
    input  wire clk,
    input  wire rst,
    input  wire use,
    input  wire reset_quota,
    output reg  [2:0] quota,
    output wire allow
);

    reg [2:0] next_quota;

    always @* begin
        if (reset_quota) next_quota = 3'd5;
        else if (!reset_quota && use && (quota > 3'd0)) next_quota = quota - 3'd1;
        else next_quota = quota;
    end

    always @(posedge clk) begin
        if (rst)
            quota <= 3'd5;
        else
            quota <= next_quota;
    end

    assign allow = quota != 3'd0;
endmodule

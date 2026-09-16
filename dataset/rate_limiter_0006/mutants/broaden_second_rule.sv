module rate_limiter_0006_mutant_broaden_second_rule (
    input  wire clk,
    input  wire rst,
    input  wire use,
    input  wire reset_quota,
    output reg  [2:0] quota,
    output wire allow
);

    always @(posedge clk) begin
        if (rst) begin
            quota <= 3'd5;
        end
        else begin
            if (reset_quota) quota <= 3'd5;
            else quota <= quota - 3'd1;
        end
    end

    assign allow = quota != 3'd0;
endmodule

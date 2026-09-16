module rate_limiter_0005_sequential_priority (
    input  wire clk,
    input  wire rst,
    input  wire grant,
    input  wire recover,
    output reg  [2:0] budget,
    output wire allow
);

    always @(posedge clk) begin
        if (rst) begin
            budget <= 3'd7;
        end
        else begin
            if (recover && (budget < 3'd7)) budget <= budget + 3'd1;
            else if (!recover && grant && (budget > 3'd0)) budget <= budget - 3'd1;
            else budget <= budget;
        end
    end

    assign allow = budget != 3'd0;
endmodule

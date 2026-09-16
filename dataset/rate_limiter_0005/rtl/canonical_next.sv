module rate_limiter_0005_canonical_next (
    input  wire clk,
    input  wire rst,
    input  wire grant,
    input  wire recover,
    output reg  [2:0] budget,
    output wire allow
);

    reg [2:0] next_budget;

    always @* begin
        if (recover && (budget < 3'd7)) next_budget = budget + 3'd1;
        else if (!recover && grant && (budget > 3'd0)) next_budget = budget - 3'd1;
        else next_budget = budget;
    end

    always @(posedge clk) begin
        if (rst)
            budget <= 3'd7;
        else
            budget <= next_budget;
    end

    assign allow = budget != 3'd0;
endmodule

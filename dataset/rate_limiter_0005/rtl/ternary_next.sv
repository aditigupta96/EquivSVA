module rate_limiter_0005_ternary_next (
    input  wire clk,
    input  wire rst,
    input  wire grant,
    input  wire recover,
    output reg  [2:0] budget,
    output wire allow
);

    wire [2:0] next_budget;

    assign next_budget = (recover && (budget < 3'd7)) ? (budget + 3'd1) : ((!recover && grant && (budget > 3'd0)) ? (budget - 3'd1) : (budget));

    always @(posedge clk) begin
        if (rst)
            budget <= 3'd7;
        else
            budget <= next_budget;
    end

    assign allow = budget != 3'd0;
endmodule

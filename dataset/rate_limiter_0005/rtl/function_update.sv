module rate_limiter_0005_function_update (
    input  wire clk,
    input  wire rst,
    input  wire grant,
    input  wire recover,
    output reg  [2:0] budget,
    output wire allow
);

    function automatic [2:0] compute_next_budget;
        input [2:0] current;
        input grant;
        input recover;
        begin
            if (recover && (current < 3'd7)) compute_next_budget = current + 3'd1;
            else if (!recover && grant && (current > 3'd0)) compute_next_budget = current - 3'd1;
            else compute_next_budget = current;
        end
    endfunction

    wire [2:0] next_budget;

    assign next_budget = compute_next_budget(budget, grant, recover);

    always @(posedge clk) begin
        if (rst)
            budget <= 3'd7;
        else
            budget <= next_budget;
    end

    assign allow = budget != 3'd0;
endmodule

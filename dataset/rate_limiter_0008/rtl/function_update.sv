module rate_limiter_0008_function_update (
    input  wire clk,
    input  wire rst,
    input  wire add,
    input  wire leak,
    output reg  [2:0] level,
    output wire blocked
);

    function automatic [2:0] compute_next_level;
        input [2:0] current;
        input add;
        input leak;
        begin
            if (add && (current < 3'd7)) compute_next_level = current + 3'd1;
            else if (!add && leak && (current > 3'd0)) compute_next_level = current - 3'd1;
            else compute_next_level = current;
        end
    endfunction

    wire [2:0] next_level;

    assign next_level = compute_next_level(level, add, leak);

    always @(posedge clk) begin
        if (rst)
            level <= 3'd0;
        else
            level <= next_level;
    end

    assign blocked = level == 3'd7;
endmodule

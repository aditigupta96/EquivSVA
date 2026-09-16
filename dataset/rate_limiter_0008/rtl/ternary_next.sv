module rate_limiter_0008_ternary_next (
    input  wire clk,
    input  wire rst,
    input  wire add,
    input  wire leak,
    output reg  [2:0] level,
    output wire blocked
);

    wire [2:0] next_level;

    assign next_level = (add && (level < 3'd7)) ? (level + 3'd1) : ((!add && leak && (level > 3'd0)) ? (level - 3'd1) : (level));

    always @(posedge clk) begin
        if (rst)
            level <= 3'd0;
        else
            level <= next_level;
    end

    assign blocked = level == 3'd7;
endmodule

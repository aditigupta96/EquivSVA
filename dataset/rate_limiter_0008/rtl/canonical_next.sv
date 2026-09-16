module rate_limiter_0008_canonical_next (
    input  wire clk,
    input  wire rst,
    input  wire add,
    input  wire leak,
    output reg  [2:0] level,
    output wire blocked
);

    reg [2:0] next_level;

    always @* begin
        if (add && (level < 3'd7)) next_level = level + 3'd1;
        else if (!add && leak && (level > 3'd0)) next_level = level - 3'd1;
        else next_level = level;
    end

    always @(posedge clk) begin
        if (rst)
            level <= 3'd0;
        else
            level <= next_level;
    end

    assign blocked = level == 3'd7;
endmodule

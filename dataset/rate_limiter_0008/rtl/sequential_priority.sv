module rate_limiter_0008_sequential_priority (
    input  wire clk,
    input  wire rst,
    input  wire add,
    input  wire leak,
    output reg  [2:0] level,
    output wire blocked
);

    always @(posedge clk) begin
        if (rst) begin
            level <= 3'd0;
        end
        else begin
            if (add && (level < 3'd7)) level <= level + 3'd1;
            else if (!add && leak && (level > 3'd0)) level <= level - 3'd1;
            else level <= level;
        end
    end

    assign blocked = level == 3'd7;
endmodule

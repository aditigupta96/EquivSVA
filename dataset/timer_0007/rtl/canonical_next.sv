module timer_0007_canonical_next (
    input  wire clk,
    input  wire rst,
    input  wire load,
    input  wire tick,
    output reg  [2:0] remaining,
    output wire expired
);

    reg [2:0] next_remaining;

    always @* begin
        if (load) next_remaining = 3'd7;
        else if (!load && tick && (remaining > 3'd0)) next_remaining = remaining - 3'd1;
        else next_remaining = remaining;
    end

    always @(posedge clk) begin
        if (rst)
            remaining <= 3'd0;
        else
            remaining <= next_remaining;
    end

    assign expired = remaining == 3'd0;
endmodule

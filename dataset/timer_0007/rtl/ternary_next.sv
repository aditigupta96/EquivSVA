module timer_0007_ternary_next (
    input  wire clk,
    input  wire rst,
    input  wire load,
    input  wire tick,
    output reg  [2:0] remaining,
    output wire expired
);

    wire [2:0] next_remaining;

    assign next_remaining = (load) ? (3'd7) : ((!load && tick && (remaining > 3'd0)) ? (remaining - 3'd1) : (remaining));

    always @(posedge clk) begin
        if (rst)
            remaining <= 3'd0;
        else
            remaining <= next_remaining;
    end

    assign expired = remaining == 3'd0;
endmodule

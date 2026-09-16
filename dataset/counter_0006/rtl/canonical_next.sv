module counter_0006_canonical_next (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire enable,
    output reg  [2:0] count,
    output wire terminal
);

    reg [2:0] next_count;

    always @* begin
        if (clear) next_count = 3'd0;
        else if (!clear && enable && (count < 3'd5)) next_count = count + 3'd1;
        else if (!clear && enable && (count == 3'd5)) next_count = 3'd0;
        else next_count = count;
    end

    always @(posedge clk) begin
        if (rst)
            count <= 3'd0;
        else
            count <= next_count;
    end

    assign terminal = count == 3'd5;
endmodule

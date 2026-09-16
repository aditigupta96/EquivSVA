module counter_0008_canonical_next (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire step,
    output reg  [2:0] count,
    output wire at_limit
);

    reg [2:0] next_count;

    always @* begin
        if (clear) next_count = 3'd0;
        else if (!clear && step && (count < 3'd6)) next_count = count + 3'd2;
        else next_count = count;
    end

    always @(posedge clk) begin
        if (rst)
            count <= 3'd0;
        else
            count <= next_count;
    end

    assign at_limit = count == 3'd6;
endmodule

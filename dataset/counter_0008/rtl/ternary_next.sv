module counter_0008_ternary_next (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire step,
    output reg  [2:0] count,
    output wire at_limit
);

    wire [2:0] next_count;

    assign next_count = (clear) ? (3'd0) : ((!clear && step && (count < 3'd6)) ? (count + 3'd2) : (count));

    always @(posedge clk) begin
        if (rst)
            count <= 3'd0;
        else
            count <= next_count;
    end

    assign at_limit = count == 3'd6;
endmodule

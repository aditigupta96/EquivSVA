module timer_0009_ternary_next (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire enable,
    output reg  [2:0] count,
    output wire done
);

    wire [2:0] next_count;

    assign next_count = (clear) ? (3'd0) : ((!clear && enable && (count < 3'd5)) ? (count + 3'd1) : (count));

    always @(posedge clk) begin
        if (rst)
            count <= 3'd0;
        else
            count <= next_count;
    end

    assign done = count == 3'd5;
endmodule

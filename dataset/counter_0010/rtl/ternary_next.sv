module counter_0010_ternary_next (
    input  wire clk,
    input  wire rst,
    input  wire load,
    input  wire increment,
    output reg  [2:0] count,
    output wire nonzero
);

    wire [2:0] next_count;

    assign next_count = (load) ? (3'd4) : ((!load && increment && (count < 3'd7)) ? (count + 3'd1) : (count));

    always @(posedge clk) begin
        if (rst)
            count <= 3'd0;
        else
            count <= next_count;
    end

    assign nonzero = count != 3'd0;
endmodule

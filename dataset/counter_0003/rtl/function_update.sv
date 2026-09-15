module counter_0003_function_update (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire enable,
    input  wire down,
    output reg  [1:0] count,
    output wire at_min,
    output wire at_max
);

    function automatic [1:0] compute_next_count;
        input [1:0] current;
        input clear;
        input enable;
        input down;
        begin
            if (clear) compute_next_count = 2'd0;
            else if (enable && down && (current > 2'd0)) compute_next_count = current - 2'd1;
            else if (enable && !down && (current < 2'd3)) compute_next_count = current + 2'd1;
            else compute_next_count = current;
        end
    endfunction

    wire [1:0] next_count;

    assign next_count = compute_next_count(count, clear, enable, down);

    always @(posedge clk) begin
        if (rst)
            count <= 2'd0;
        else
            count <= next_count;
    end

    assign at_min = count == 2'd0;
    assign at_max = count == 2'd3;
endmodule

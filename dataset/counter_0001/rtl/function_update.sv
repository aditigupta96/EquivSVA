module counter_0001_function_update (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire enable,
    output reg  [1:0] count,
    output wire at_max
);

    function automatic [1:0] compute_next_count;
        input [1:0] current;
        input clear;
        input enable;
        begin
            if (clear) compute_next_count = 2'd0;
            else if (enable && (current < 2'd3)) compute_next_count = current + 2'd1;
            else compute_next_count = current;
        end
    endfunction

    wire [1:0] next_count;

    assign next_count = compute_next_count(count, clear, enable);

    always @(posedge clk) begin
        if (rst)
            count <= 2'd0;
        else
            count <= next_count;
    end

    assign at_max = count == 2'd3;
endmodule

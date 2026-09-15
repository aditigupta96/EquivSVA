module counter_0004_function_update (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire load,
    input  wire enable,
    input  wire [1:0] load_value,
    output reg  [1:0] count,
    output wire at_max
);

    function automatic [1:0] compute_next_count;
        input [1:0] current;
        input clear;
        input load;
        input enable;
        input [1:0] load_value;
        begin
            if (clear) compute_next_count = 2'd0;
            else if (load) compute_next_count = load_value;
            else if (enable && (current < 2'd3)) compute_next_count = current + 2'd1;
            else compute_next_count = current;
        end
    endfunction

    wire [1:0] next_count;

    assign next_count = compute_next_count(count, clear, load, enable, load_value);

    always @(posedge clk) begin
        if (rst)
            count <= 2'd0;
        else
            count <= next_count;
    end

    assign at_max = count == 2'd3;
endmodule

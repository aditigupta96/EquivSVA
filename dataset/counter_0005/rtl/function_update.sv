module counter_0005_function_update (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire load,
    input  wire tick,
    input  wire [1:0] load_value,
    output reg  [1:0] count,
    output wire expired
);

    function automatic [1:0] compute_next_count;
        input [1:0] current;
        input clear;
        input load;
        input tick;
        input [1:0] load_value;
        begin
            if (clear) compute_next_count = 2'd0;
            else if (load) compute_next_count = load_value;
            else if (tick && (current > 2'd0)) compute_next_count = current - 2'd1;
            else compute_next_count = current;
        end
    endfunction

    wire [1:0] next_count;

    assign next_count = compute_next_count(count, clear, load, tick, load_value);

    always @(posedge clk) begin
        if (rst)
            count <= 2'd0;
        else
            count <= next_count;
    end

    assign expired = count == 2'd0;
endmodule

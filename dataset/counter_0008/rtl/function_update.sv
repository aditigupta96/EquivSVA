module counter_0008_function_update (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire step,
    output reg  [2:0] count,
    output wire at_limit
);

    function automatic [2:0] compute_next_count;
        input [2:0] current;
        input clear;
        input step;
        begin
            if (clear) compute_next_count = 3'd0;
            else if (!clear && step && (current < 3'd6)) compute_next_count = current + 3'd2;
            else compute_next_count = current;
        end
    endfunction

    wire [2:0] next_count;

    assign next_count = compute_next_count(count, clear, step);

    always @(posedge clk) begin
        if (rst)
            count <= 3'd0;
        else
            count <= next_count;
    end

    assign at_limit = count == 3'd6;
endmodule

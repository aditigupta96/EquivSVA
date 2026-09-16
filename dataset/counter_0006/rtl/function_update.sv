module counter_0006_function_update (
    input  wire clk,
    input  wire rst,
    input  wire clear,
    input  wire enable,
    output reg  [2:0] count,
    output wire terminal
);

    function automatic [2:0] compute_next_count;
        input [2:0] current;
        input clear;
        input enable;
        begin
            if (clear) compute_next_count = 3'd0;
            else if (!clear && enable && (current < 3'd5)) compute_next_count = current + 3'd1;
            else if (!clear && enable && (current == 3'd5)) compute_next_count = 3'd0;
            else compute_next_count = current;
        end
    endfunction

    wire [2:0] next_count;

    assign next_count = compute_next_count(count, clear, enable);

    always @(posedge clk) begin
        if (rst)
            count <= 3'd0;
        else
            count <= next_count;
    end

    assign terminal = count == 3'd5;
endmodule

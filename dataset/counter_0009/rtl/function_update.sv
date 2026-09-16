module counter_0009_function_update (
    input  wire clk,
    input  wire rst,
    input  wire up,
    input  wire down,
    output reg  [2:0] count,
    output wire at_zero,
    output wire at_max
);

    function automatic [2:0] compute_next_count;
        input [2:0] current;
        input up;
        input down;
        begin
            if (up && !down && (current < 3'd7)) compute_next_count = current + 3'd1;
            else if (down && !up && (current > 3'd0)) compute_next_count = current - 3'd1;
            else compute_next_count = current;
        end
    endfunction

    wire [2:0] next_count;

    assign next_count = compute_next_count(count, up, down);

    always @(posedge clk) begin
        if (rst)
            count <= 3'd0;
        else
            count <= next_count;
    end

    assign at_zero = count == 3'd0;
    assign at_max = count == 3'd7;
endmodule

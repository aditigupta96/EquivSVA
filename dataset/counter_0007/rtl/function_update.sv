module counter_0007_function_update (
    input  wire clk,
    input  wire rst,
    input  wire reload,
    input  wire enable,
    output reg  [2:0] count,
    output wire at_zero
);

    function automatic [2:0] compute_next_count;
        input [2:0] current;
        input reload;
        input enable;
        begin
            if (reload) compute_next_count = 3'd7;
            else if (!reload && enable && (current > 3'd0)) compute_next_count = current - 3'd1;
            else compute_next_count = current;
        end
    endfunction

    wire [2:0] next_count;

    assign next_count = compute_next_count(count, reload, enable);

    always @(posedge clk) begin
        if (rst)
            count <= 3'd7;
        else
            count <= next_count;
    end

    assign at_zero = count == 3'd0;
endmodule

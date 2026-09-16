module counter_0010_function_update (
    input  wire clk,
    input  wire rst,
    input  wire load,
    input  wire increment,
    output reg  [2:0] count,
    output wire nonzero
);

    function automatic [2:0] compute_next_count;
        input [2:0] current;
        input load;
        input increment;
        begin
            if (load) compute_next_count = 3'd4;
            else if (!load && increment && (current < 3'd7)) compute_next_count = current + 3'd1;
            else compute_next_count = current;
        end
    endfunction

    wire [2:0] next_count;

    assign next_count = compute_next_count(count, load, increment);

    always @(posedge clk) begin
        if (rst)
            count <= 3'd0;
        else
            count <= next_count;
    end

    assign nonzero = count != 3'd0;
endmodule

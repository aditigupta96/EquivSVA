module timer_0007_function_update (
    input  wire clk,
    input  wire rst,
    input  wire load,
    input  wire tick,
    output reg  [2:0] remaining,
    output wire expired
);

    function automatic [2:0] compute_next_remaining;
        input [2:0] current;
        input load;
        input tick;
        begin
            if (load) compute_next_remaining = 3'd7;
            else if (!load && tick && (current > 3'd0)) compute_next_remaining = current - 3'd1;
            else compute_next_remaining = current;
        end
    endfunction

    wire [2:0] next_remaining;

    assign next_remaining = compute_next_remaining(remaining, load, tick);

    always @(posedge clk) begin
        if (rst)
            remaining <= 3'd0;
        else
            remaining <= next_remaining;
    end

    assign expired = remaining == 3'd0;
endmodule

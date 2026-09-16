module timer_0008_function_update (
    input  wire clk,
    input  wire rst,
    input  wire kick,
    input  wire tick,
    output reg  [2:0] age,
    output wire timeout
);

    function automatic [2:0] compute_next_age;
        input [2:0] current;
        input kick;
        input tick;
        begin
            if (kick) compute_next_age = 3'd0;
            else if (!kick && tick && (current < 3'd7)) compute_next_age = current + 3'd1;
            else compute_next_age = current;
        end
    endfunction

    wire [2:0] next_age;

    assign next_age = compute_next_age(age, kick, tick);

    always @(posedge clk) begin
        if (rst)
            age <= 3'd0;
        else
            age <= next_age;
    end

    assign timeout = age == 3'd7;
endmodule

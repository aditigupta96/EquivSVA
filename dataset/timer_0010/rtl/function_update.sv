module timer_0010_function_update (
    input  wire clk,
    input  wire rst,
    input  wire restart,
    input  wire tick,
    output reg  [2:0] phase,
    output wire terminal
);

    function automatic [2:0] compute_next_phase;
        input [2:0] current;
        input restart;
        input tick;
        begin
            if (restart) compute_next_phase = 3'd0;
            else if (!restart && tick && (current < 3'd7)) compute_next_phase = current + 3'd1;
            else if (!restart && tick && (current == 3'd7)) compute_next_phase = 3'd0;
            else compute_next_phase = current;
        end
    endfunction

    wire [2:0] next_phase;

    assign next_phase = compute_next_phase(phase, restart, tick);

    always @(posedge clk) begin
        if (rst)
            phase <= 3'd0;
        else
            phase <= next_phase;
    end

    assign terminal = phase == 3'd7;
endmodule

module timer_0010_ternary_next (
    input  wire clk,
    input  wire rst,
    input  wire restart,
    input  wire tick,
    output reg  [2:0] phase,
    output wire terminal
);

    wire [2:0] next_phase;

    assign next_phase = (restart) ? (3'd0) : ((!restart && tick && (phase < 3'd7)) ? (phase + 3'd1) : ((!restart && tick && (phase == 3'd7)) ? (3'd0) : (phase)));

    always @(posedge clk) begin
        if (rst)
            phase <= 3'd0;
        else
            phase <= next_phase;
    end

    assign terminal = phase == 3'd7;
endmodule

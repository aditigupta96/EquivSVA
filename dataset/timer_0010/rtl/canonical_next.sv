module timer_0010_canonical_next (
    input  wire clk,
    input  wire rst,
    input  wire restart,
    input  wire tick,
    output reg  [2:0] phase,
    output wire terminal
);

    reg [2:0] next_phase;

    always @* begin
        if (restart) next_phase = 3'd0;
        else if (!restart && tick && (phase < 3'd7)) next_phase = phase + 3'd1;
        else if (!restart && tick && (phase == 3'd7)) next_phase = 3'd0;
        else next_phase = phase;
    end

    always @(posedge clk) begin
        if (rst)
            phase <= 3'd0;
        else
            phase <= next_phase;
    end

    assign terminal = phase == 3'd7;
endmodule

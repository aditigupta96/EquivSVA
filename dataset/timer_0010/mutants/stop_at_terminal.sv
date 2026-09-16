module timer_0010_mutant_stop_at_terminal (
    input  wire clk,
    input  wire rst,
    input  wire restart,
    input  wire tick,
    output reg  [2:0] phase,
    output wire terminal
);

    always @(posedge clk) begin
        if (rst) begin
            phase <= 3'd0;
        end
        else begin
            if (restart) phase <= 3'd0;
            else if (!restart && tick && (phase < 3'd7)) phase <= phase + 3'd1;
            else phase <= phase;
        end
    end

    assign terminal = phase == 3'd7;
endmodule

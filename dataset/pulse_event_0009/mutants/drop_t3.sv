module pulse_event_0009_mutant_drop_t3 (
    input  wire clk,
    input  wire rst,
    input  wire request,
    input  wire complete,
    output reg  waiting,
    output reg  pulse,
    output reg  idle
);
    localparam [1:0] IDLE  = 2'd0;
    localparam [1:0] WAIT  = 2'd1;
    localparam [1:0] PULSE = 2'd2;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            IDLE: next_state = (request) ? WAIT : ((!request) ? IDLE : (IDLE));
            WAIT: next_state = (!complete) ? WAIT : (WAIT);
            PULSE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @* begin
        waiting = 1'b0;
        pulse = 1'b0;
        idle = 1'b0;
        case (state)
            IDLE: begin
                waiting = 1'b0;
                pulse = 1'b0;
                idle = 1'b1;
            end
            WAIT: begin
                waiting = 1'b1;
                pulse = 1'b0;
                idle = 1'b0;
            end
            PULSE: begin
                waiting = 1'b0;
                pulse = 1'b1;
                idle = 1'b0;
            end
            default: begin end
        endcase
    end
endmodule

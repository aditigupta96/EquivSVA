module pulse_event_0009_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire request,
    input  wire complete,
    output reg  waiting,
    output reg  pulse,
    output reg  idle
);
    localparam [2:0] IDLE  = 3'b001;
    localparam [2:0] WAIT  = 3'b010;
    localparam [2:0] PULSE = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (request) ? WAIT : ((!request) ? IDLE : (IDLE));
            WAIT: next_state = (complete) ? PULSE : ((!complete) ? WAIT : (WAIT));
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
        waiting = (state == WAIT);
        pulse = (state == PULSE);
        idle = (state == IDLE);
    end
endmodule

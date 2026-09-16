module pulse_event_0010_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire arm,
    input  wire trigger,
    input  wire rearm,
    output reg  disarmed,
    output reg  armed,
    output reg  pulse,
    output reg  spent
);
    localparam [3:0] DISARMED = 4'b0001;
    localparam [3:0] ARMED = 4'b0010;
    localparam [3:0] PULSE = 4'b0100;
    localparam [3:0] SPENT = 4'b1000;

    reg [3:0] state, next_state;

    always @* begin
        next_state = DISARMED;
        case (state)
            DISARMED: next_state = (arm) ? ARMED : ((!arm) ? DISARMED : (DISARMED));
            ARMED: next_state = (trigger) ? PULSE : ((!trigger) ? ARMED : (ARMED));
            PULSE: next_state = SPENT;
            SPENT: next_state = (rearm) ? ARMED : ((!rearm) ? SPENT : (SPENT));
            default: next_state = DISARMED;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= DISARMED;
        else
            state <= next_state;
    end

    always @* begin
        disarmed = (state == DISARMED);
        armed = (state == ARMED);
        pulse = (state == PULSE);
        spent = (state == SPENT);
    end
endmodule

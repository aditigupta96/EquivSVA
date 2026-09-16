module pulse_event_0005_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire event_in,
    output reg  armed,
    output reg  qualifying,
    output reg  pulse,
    output reg  rearming
);
    localparam [4:0] ARMED = 5'b00001;
    localparam [4:0] HIGH1 = 5'b00010;
    localparam [4:0] PULSE = 5'b00100;
    localparam [4:0] WAIT_LOW = 5'b01000;
    localparam [4:0] LOW1  = 5'b10000;

    reg [4:0] state, next_state;

    always @* begin
        next_state = ARMED;
        case (state)
            ARMED: next_state = (event_in) ? HIGH1 : ((!event_in) ? ARMED : (ARMED));
            HIGH1: next_state = (event_in) ? PULSE : ((!event_in) ? ARMED : (HIGH1));
            PULSE: next_state = WAIT_LOW;
            WAIT_LOW: next_state = (!event_in) ? LOW1 : ((event_in) ? WAIT_LOW : (WAIT_LOW));
            LOW1: next_state = (!event_in) ? ARMED : ((event_in) ? WAIT_LOW : (LOW1));
            default: next_state = ARMED;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= ARMED;
        else
            state <= next_state;
    end

    always @* begin
        armed = (state == ARMED);
        qualifying = (state == HIGH1);
        pulse = (state == PULSE);
        rearming = (state == WAIT_LOW) || (state == LOW1);
    end
endmodule

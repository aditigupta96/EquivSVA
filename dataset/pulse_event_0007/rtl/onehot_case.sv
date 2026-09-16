module pulse_event_0007_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire trigger,
    output reg  armed,
    output reg  pulse,
    output reg  cooldown1,
    output reg  cooldown2
);
    localparam [3:0] ARMED = 4'b0001;
    localparam [3:0] PULSE = 4'b0010;
    localparam [3:0] COOL1 = 4'b0100;
    localparam [3:0] COOL2 = 4'b1000;

    reg [3:0] state, next_state;

    always @* begin
        next_state = ARMED;
        case (state)
            ARMED: next_state = (trigger) ? PULSE : ((!trigger) ? ARMED : (ARMED));
            PULSE: next_state = COOL1;
            COOL1: next_state = COOL2;
            COOL2: next_state = ARMED;
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
        pulse = (state == PULSE);
        cooldown1 = (state == COOL1);
        cooldown2 = (state == COOL2);
    end
endmodule

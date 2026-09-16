module pulse_event_0010_mutant_arm_ignored (
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
    localparam [1:0] DISARMED = 2'd0;
    localparam [1:0] ARMED = 2'd1;
    localparam [1:0] PULSE = 2'd2;
    localparam [1:0] SPENT = 2'd3;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            DISARMED: next_state = (!arm) ? DISARMED : (DISARMED);
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
        disarmed = 1'b0;
        armed = 1'b0;
        pulse = 1'b0;
        spent = 1'b0;
        case (state)
            DISARMED: begin
                disarmed = 1'b1;
                armed = 1'b0;
                pulse = 1'b0;
                spent = 1'b0;
            end
            ARMED: begin
                disarmed = 1'b0;
                armed = 1'b1;
                pulse = 1'b0;
                spent = 1'b0;
            end
            PULSE: begin
                disarmed = 1'b0;
                armed = 1'b0;
                pulse = 1'b1;
                spent = 1'b0;
            end
            SPENT: begin
                disarmed = 1'b0;
                armed = 1'b0;
                pulse = 1'b0;
                spent = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

module pulse_event_0007_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire trigger,
    output reg  armed,
    output reg  pulse,
    output reg  cooldown
);
    localparam [1:0] F_ARMED        = 2'd0;
    localparam [1:0] F_PULSE        = 2'd1;
    localparam [1:0] F_COOL1        = 2'd2;
    localparam [1:0] F_COOL2        = 2'd3;

    reg [1:0] state, next_state;

    wire guard_armed_0 = (trigger);
    wire guard_armed_1 = (!trigger);

    always @* begin
        next_state = state;
        case (state)
            F_ARMED: begin
                if (guard_armed_0)
                    next_state = F_PULSE;
                else if (guard_armed_1)
                    next_state = F_ARMED;
            end
            F_PULSE: begin
                next_state = F_COOL1;
            end
            F_COOL1: begin
                next_state = F_COOL2;
            end
            F_COOL2: begin
                next_state = F_ARMED;
            end
            default: next_state = F_ARMED;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= F_ARMED;
        else
            state <= next_state;
    end

    always @* begin
        armed = 1'b0;
        pulse = 1'b0;
        cooldown = 1'b0;
        case (state)
            F_ARMED: begin
                armed = 1'b1;
                pulse = 1'b0;
                cooldown = 1'b0;
            end
            F_PULSE: begin
                armed = 1'b0;
                pulse = 1'b1;
                cooldown = 1'b0;
            end
            F_COOL1: begin
                armed = 1'b0;
                pulse = 1'b0;
                cooldown = 1'b1;
            end
            F_COOL2: begin
                armed = 1'b0;
                pulse = 1'b0;
                cooldown = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

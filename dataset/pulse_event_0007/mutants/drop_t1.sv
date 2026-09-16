module pulse_event_0007_mutant_drop_t1 (
    input  wire clk,
    input  wire rst,
    input  wire trigger,
    output reg  armed,
    output reg  pulse,
    output reg  cooldown
);
    localparam [1:0] ARMED = 2'd0;
    localparam [1:0] PULSE = 2'd1;
    localparam [1:0] COOL1 = 2'd2;
    localparam [1:0] COOL2 = 2'd3;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            ARMED: next_state = (!trigger) ? ARMED : (ARMED);
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
        armed = 1'b0;
        pulse = 1'b0;
        cooldown = 1'b0;
        case (state)
            ARMED: begin
                armed = 1'b1;
                pulse = 1'b0;
                cooldown = 1'b0;
            end
            PULSE: begin
                armed = 1'b0;
                pulse = 1'b1;
                cooldown = 1'b0;
            end
            COOL1: begin
                armed = 1'b0;
                pulse = 1'b0;
                cooldown = 1'b1;
            end
            COOL2: begin
                armed = 1'b0;
                pulse = 1'b0;
                cooldown = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

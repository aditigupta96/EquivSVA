module pulse_event_0002_mutant_drop_t1 (
    input  wire clk,
    input  wire rst,
    input  wire event_in,
    output reg  armed,
    output reg  pulse,
    output reg  blocked
);
    localparam [1:0] ARMED = 2'd0;
    localparam [1:0] PULSE = 2'd1;
    localparam [1:0] BLOCKED = 2'd2;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            ARMED: next_state = (!event_in) ? ARMED : (ARMED);
            PULSE: next_state = BLOCKED;
            BLOCKED: next_state = (event_in) ? BLOCKED : ((!event_in) ? ARMED : (BLOCKED));
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
        blocked = 1'b0;
        case (state)
            ARMED: begin
                armed = 1'b1;
                pulse = 1'b0;
                blocked = 1'b0;
            end
            PULSE: begin
                armed = 1'b0;
                pulse = 1'b1;
                blocked = 1'b0;
            end
            BLOCKED: begin
                armed = 1'b0;
                pulse = 1'b0;
                blocked = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

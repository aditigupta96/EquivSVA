module pulse_event_0004_mutant_drop_t1 (
    input  wire clk,
    input  wire rst,
    input  wire trigger,
    input  wire clear,
    output reg  armed,
    output reg  pulse,
    output reg  latched
);
    localparam [1:0] ARMED = 2'd0;
    localparam [1:0] PULSE = 2'd1;
    localparam [1:0] LATCHED = 2'd2;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            ARMED: next_state = (!trigger) ? ARMED : (ARMED);
            PULSE: next_state = LATCHED;
            LATCHED: next_state = (clear) ? ARMED : ((!clear) ? LATCHED : (LATCHED));
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
        latched = 1'b0;
        case (state)
            ARMED: begin
                armed = 1'b1;
                pulse = 1'b0;
                latched = 1'b0;
            end
            PULSE: begin
                armed = 1'b0;
                pulse = 1'b1;
                latched = 1'b0;
            end
            LATCHED: begin
                armed = 1'b0;
                pulse = 1'b0;
                latched = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

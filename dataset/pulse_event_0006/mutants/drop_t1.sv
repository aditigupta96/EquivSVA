module pulse_event_0006_mutant_drop_t1 (
    input  wire clk,
    input  wire rst,
    input  wire trigger,
    input  wire cancel,
    output reg  armed,
    output reg  pulse,
    output reg  cancelled
);
    localparam [1:0] ARMED = 2'd0;
    localparam [1:0] PULSE = 2'd1;
    localparam [1:0] CANCEL = 2'd2;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            ARMED: next_state = (cancel) ? CANCEL : ((!trigger && !cancel) ? ARMED : (ARMED));
            PULSE: next_state = ARMED;
            CANCEL: next_state = ARMED;
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
        cancelled = 1'b0;
        case (state)
            ARMED: begin
                armed = 1'b1;
                pulse = 1'b0;
                cancelled = 1'b0;
            end
            PULSE: begin
                armed = 1'b0;
                pulse = 1'b1;
                cancelled = 1'b0;
            end
            CANCEL: begin
                armed = 1'b0;
                pulse = 1'b0;
                cancelled = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

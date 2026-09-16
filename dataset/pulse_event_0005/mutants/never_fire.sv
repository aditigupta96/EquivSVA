module pulse_event_0005_mutant_never_fire (
    input  wire clk,
    input  wire rst,
    input  wire event_in,
    output reg  armed,
    output reg  qualifying,
    output reg  pulse,
    output reg  rearming
);
    localparam [2:0] ARMED = 3'd0;
    localparam [2:0] HIGH1 = 3'd1;
    localparam [2:0] PULSE = 3'd2;
    localparam [2:0] WAIT_LOW = 3'd3;
    localparam [2:0] LOW1  = 3'd4;

    reg [2:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            ARMED: next_state = (event_in) ? HIGH1 : ((!event_in) ? ARMED : (ARMED));
            HIGH1: next_state = (!event_in) ? ARMED : (HIGH1);
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
        armed = 1'b0;
        qualifying = 1'b0;
        pulse = 1'b0;
        rearming = 1'b0;
        case (state)
            ARMED: begin
                armed = 1'b1;
                qualifying = 1'b0;
                pulse = 1'b0;
                rearming = 1'b0;
            end
            HIGH1: begin
                armed = 1'b0;
                qualifying = 1'b1;
                pulse = 1'b0;
                rearming = 1'b0;
            end
            PULSE: begin
                armed = 1'b0;
                qualifying = 1'b0;
                pulse = 1'b1;
                rearming = 1'b0;
            end
            WAIT_LOW: begin
                armed = 1'b0;
                qualifying = 1'b0;
                pulse = 1'b0;
                rearming = 1'b1;
            end
            LOW1: begin
                armed = 1'b0;
                qualifying = 1'b0;
                pulse = 1'b0;
                rearming = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

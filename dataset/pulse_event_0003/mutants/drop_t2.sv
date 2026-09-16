module pulse_event_0003_mutant_drop_t2 (
    input  wire clk,
    input  wire rst,
    input  wire event_in,
    output reg  waiting_high,
    output reg  pulse,
    output reg  waiting_low
);
    localparam [1:0] WAIT_HIGH = 2'd0;
    localparam [1:0] PULSE = 2'd1;
    localparam [1:0] WAIT_LOW = 2'd2;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            WAIT_HIGH: next_state = (event_in) ? WAIT_LOW : (WAIT_HIGH);
            PULSE: next_state = WAIT_HIGH;
            WAIT_LOW: next_state = (!event_in) ? PULSE : ((event_in) ? WAIT_LOW : (WAIT_LOW));
            default: next_state = WAIT_HIGH;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= WAIT_HIGH;
        else
            state <= next_state;
    end

    always @* begin
        waiting_high = 1'b0;
        pulse = 1'b0;
        waiting_low = 1'b0;
        case (state)
            WAIT_HIGH: begin
                waiting_high = 1'b1;
                pulse = 1'b0;
                waiting_low = 1'b0;
            end
            PULSE: begin
                waiting_high = 1'b0;
                pulse = 1'b1;
                waiting_low = 1'b0;
            end
            WAIT_LOW: begin
                waiting_high = 1'b0;
                pulse = 1'b0;
                waiting_low = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

module pulse_event_0003_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire event_in,
    output reg  waiting_high,
    output reg  pulse,
    output reg  waiting_low
);
    localparam [2:0] WAIT_HIGH = 3'b001;
    localparam [2:0] PULSE = 3'b010;
    localparam [2:0] WAIT_LOW = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = WAIT_HIGH;
        case (state)
            WAIT_HIGH: next_state = (event_in) ? WAIT_LOW : ((!event_in) ? WAIT_HIGH : (WAIT_HIGH));
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
        waiting_high = (state == WAIT_HIGH);
        pulse = (state == PULSE);
        waiting_low = (state == WAIT_LOW);
    end
endmodule

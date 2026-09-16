module pulse_event_0001_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire event_in,
    output reg  pulse,
    output reg  armed
);
    localparam [2:0] IDLE  = 3'b001;
    localparam [2:0] FIRE  = 3'b010;
    localparam [2:0] WAIT_LOW = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (event_in) ? FIRE : ((!event_in) ? IDLE : (IDLE));
            FIRE: next_state = WAIT_LOW;
            WAIT_LOW: next_state = (event_in) ? WAIT_LOW : ((!event_in) ? IDLE : (WAIT_LOW));
            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @* begin
        pulse = (state == FIRE);
        armed = (state == IDLE);
    end
endmodule

module pulse_event_0001_mutant_fire_without_event (
    input  wire clk,
    input  wire rst,
    input  wire event_in,
    output reg  pulse,
    output reg  armed
);
    localparam [1:0] IDLE  = 2'd0;
    localparam [1:0] FIRE  = 2'd1;
    localparam [1:0] WAIT_LOW = 2'd2;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            IDLE: next_state = FIRE;
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
        pulse = 1'b0;
        armed = 1'b0;
        case (state)
            IDLE: begin
                pulse = 1'b0;
                armed = 1'b1;
            end
            FIRE: begin
                pulse = 1'b1;
                armed = 1'b0;
            end
            WAIT_LOW: begin
                pulse = 1'b0;
                armed = 1'b0;
            end
            default: begin end
        endcase
    end
endmodule

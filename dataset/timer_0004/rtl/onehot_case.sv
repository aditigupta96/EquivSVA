module timer_0004_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire start,
    output reg  active,
    output reg  tick
);
    localparam [2:0] IDLE  = 3'b001;
    localparam [2:0] RUN   = 3'b010;
    localparam [2:0] TICK  = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (start) ? RUN : (IDLE);
            RUN: next_state = TICK;
            TICK: next_state = RUN;
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
        active = (state == RUN) || (state == TICK);
        tick = (state == TICK);
    end
endmodule

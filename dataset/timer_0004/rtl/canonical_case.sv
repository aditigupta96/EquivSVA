module timer_0004_canonical_case (
    input  wire clk,
    input  wire rst,
    input  wire start,
    output reg  active,
    output reg  tick
);
    localparam [1:0] IDLE  = 2'd0;
    localparam [1:0] RUN   = 2'd1;
    localparam [1:0] TICK  = 2'd2;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
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
        active = 1'b0;
        tick = 1'b0;
        case (state)
            IDLE: begin
                active = 1'b0;
                tick = 1'b0;
            end
            RUN: begin
                active = 1'b1;
                tick = 1'b0;
            end
            TICK: begin
                active = 1'b1;
                tick = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

module timer_0004_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire start,
    output reg  active,
    output reg  tick
);
    localparam [1:0] F_IDLE         = 2'd0;
    localparam [1:0] F_RUN          = 2'd1;
    localparam [1:0] F_TICK         = 2'd2;

    reg [1:0] state, next_state;

    wire guard_idle_0 = (start);

    always @* begin
        next_state = state;
        case (state)
            F_IDLE: begin
                if (guard_idle_0)
                    next_state = F_RUN;
                else
                    next_state = F_IDLE;
            end
            F_RUN: begin
                next_state = F_TICK;
            end
            F_TICK: begin
                next_state = F_RUN;
            end
            default: next_state = F_IDLE;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= F_IDLE;
        else
            state <= next_state;
    end

    always @* begin
        active = 1'b0;
        tick = 1'b0;
        case (state)
            F_IDLE: begin
                active = 1'b0;
                tick = 1'b0;
            end
            F_RUN: begin
                active = 1'b1;
                tick = 1'b0;
            end
            F_TICK: begin
                active = 1'b1;
                tick = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

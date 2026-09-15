module interrupt_0002_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire irq,
    input  wire mask,
    input  wire ack,
    output reg  pending
);
    localparam [0:0] F_IDLE         = 1'd0;
    localparam [0:0] F_PENDING      = 1'd1;

    reg [0:0] state, next_state;

    wire guard_idle_0 = (irq && !mask);
    wire guard_pending_0 = (ack);

    always @* begin
        next_state = state;
        case (state)
            F_IDLE: begin
                if (guard_idle_0)
                    next_state = F_PENDING;
                else
                    next_state = F_IDLE;
            end
            F_PENDING: begin
                if (guard_pending_0)
                    next_state = F_IDLE;
                else
                    next_state = F_PENDING;
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
        pending = 1'b0;
        case (state)
            F_IDLE: begin
                pending = 1'b0;
            end
            F_PENDING: begin
                pending = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

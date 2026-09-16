module interrupt_0007_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire irq,
    input  wire mask,
    input  wire ack,
    output reg  pending,
    output reg  held_masked,
    output reg  servicing
);
    localparam [1:0] F_IDLE         = 2'd0;
    localparam [1:0] F_PENDING      = 2'd1;
    localparam [1:0] F_HELD         = 2'd2;
    localparam [1:0] F_SERVICE      = 2'd3;

    reg [1:0] state, next_state;

    wire guard_idle_0 = (irq && !mask);
    wire guard_idle_1 = (!(irq && !mask));
    wire guard_pending_0 = (mask);
    wire guard_pending_1 = (!mask && ack);
    wire guard_pending_2 = (!mask && !ack);
    wire guard_held_0 = (mask);
    wire guard_held_1 = (!mask);

    always @* begin
        next_state = state;
        case (state)
            F_IDLE: begin
                if (guard_idle_0)
                    next_state = F_PENDING;
                else if (guard_idle_1)
                    next_state = F_IDLE;
            end
            F_PENDING: begin
                if (guard_pending_0)
                    next_state = F_HELD;
                else if (guard_pending_1)
                    next_state = F_SERVICE;
                else if (guard_pending_2)
                    next_state = F_PENDING;
            end
            F_HELD: begin
                if (guard_held_0)
                    next_state = F_HELD;
                else if (guard_held_1)
                    next_state = F_PENDING;
            end
            F_SERVICE: begin
                next_state = F_IDLE;
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
        held_masked = 1'b0;
        servicing = 1'b0;
        case (state)
            F_IDLE: begin
                pending = 1'b0;
                held_masked = 1'b0;
                servicing = 1'b0;
            end
            F_PENDING: begin
                pending = 1'b1;
                held_masked = 1'b0;
                servicing = 1'b0;
            end
            F_HELD: begin
                pending = 1'b0;
                held_masked = 1'b1;
                servicing = 1'b0;
            end
            F_SERVICE: begin
                pending = 1'b0;
                held_masked = 1'b0;
                servicing = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

module interrupt_0006_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire irq,
    input  wire mask,
    input  wire ack,
    output reg  pending,
    output reg  servicing
);
    localparam [1:0] F_IDLE         = 2'd0;
    localparam [1:0] F_PENDING      = 2'd1;
    localparam [1:0] F_SERVICE      = 2'd2;

    reg [1:0] state, next_state;

    wire guard_idle_0 = (irq && !mask);
    wire guard_idle_1 = (!(irq && !mask));
    wire guard_pending_0 = (ack);
    wire guard_pending_1 = (!ack);

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
                    next_state = F_SERVICE;
                else if (guard_pending_1)
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
        servicing = 1'b0;
        case (state)
            F_IDLE: begin
                pending = 1'b0;
                servicing = 1'b0;
            end
            F_PENDING: begin
                pending = 1'b1;
                servicing = 1'b0;
            end
            F_SERVICE: begin
                pending = 1'b0;
                servicing = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

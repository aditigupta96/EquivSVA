module interrupt_0008_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire irq_hi,
    input  wire irq_lo,
    input  wire ack,
    output reg  low_pending,
    output reg  high_pending,
    output reg  service
);
    localparam [1:0] F_IDLE         = 2'd0;
    localparam [1:0] F_LOW          = 2'd1;
    localparam [1:0] F_HIGH         = 2'd2;
    localparam [1:0] F_SERVICE      = 2'd3;

    reg [1:0] state, next_state;

    wire guard_idle_0 = (irq_hi);
    wire guard_idle_1 = (!irq_hi && irq_lo);
    wire guard_idle_2 = (!irq_hi && !irq_lo);
    wire guard_low_0 = (irq_hi);
    wire guard_low_1 = (!irq_hi && ack);
    wire guard_low_2 = (!irq_hi && !ack);
    wire guard_high_0 = (ack);
    wire guard_high_1 = (!ack);

    always @* begin
        next_state = state;
        case (state)
            F_IDLE: begin
                if (guard_idle_0)
                    next_state = F_HIGH;
                else if (guard_idle_1)
                    next_state = F_LOW;
                else if (guard_idle_2)
                    next_state = F_IDLE;
            end
            F_LOW: begin
                if (guard_low_0)
                    next_state = F_HIGH;
                else if (guard_low_1)
                    next_state = F_SERVICE;
                else if (guard_low_2)
                    next_state = F_LOW;
            end
            F_HIGH: begin
                if (guard_high_0)
                    next_state = F_SERVICE;
                else if (guard_high_1)
                    next_state = F_HIGH;
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
        low_pending = 1'b0;
        high_pending = 1'b0;
        service = 1'b0;
        case (state)
            F_IDLE: begin
                low_pending = 1'b0;
                high_pending = 1'b0;
                service = 1'b0;
            end
            F_LOW: begin
                low_pending = 1'b1;
                high_pending = 1'b0;
                service = 1'b0;
            end
            F_HIGH: begin
                low_pending = 1'b0;
                high_pending = 1'b1;
                service = 1'b0;
            end
            F_SERVICE: begin
                low_pending = 1'b0;
                high_pending = 1'b0;
                service = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

module interrupt_0009_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire irq,
    input  wire ack,
    output reg  pending,
    output reg  servicing,
    output reg  wait_low,
    output reg  armed
);
    localparam [1:0] F_ARMED        = 2'd0;
    localparam [1:0] F_PENDING      = 2'd1;
    localparam [1:0] F_SERVICE      = 2'd2;
    localparam [1:0] F_WAIT_LOW     = 2'd3;

    reg [1:0] state, next_state;

    wire guard_armed_0 = (irq);
    wire guard_armed_1 = (!irq);
    wire guard_pending_0 = (ack);
    wire guard_pending_1 = (!ack);
    wire guard_wait_low_0 = (irq);
    wire guard_wait_low_1 = (!irq);

    always @* begin
        next_state = state;
        case (state)
            F_ARMED: begin
                if (guard_armed_0)
                    next_state = F_PENDING;
                else if (guard_armed_1)
                    next_state = F_ARMED;
            end
            F_PENDING: begin
                if (guard_pending_0)
                    next_state = F_SERVICE;
                else if (guard_pending_1)
                    next_state = F_PENDING;
            end
            F_SERVICE: begin
                next_state = F_WAIT_LOW;
            end
            F_WAIT_LOW: begin
                if (guard_wait_low_0)
                    next_state = F_WAIT_LOW;
                else if (guard_wait_low_1)
                    next_state = F_ARMED;
            end
            default: next_state = F_ARMED;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= F_ARMED;
        else
            state <= next_state;
    end

    always @* begin
        pending = 1'b0;
        servicing = 1'b0;
        wait_low = 1'b0;
        armed = 1'b0;
        case (state)
            F_ARMED: begin
                pending = 1'b0;
                servicing = 1'b0;
                wait_low = 1'b0;
                armed = 1'b1;
            end
            F_PENDING: begin
                pending = 1'b1;
                servicing = 1'b0;
                wait_low = 1'b0;
                armed = 1'b0;
            end
            F_SERVICE: begin
                pending = 1'b0;
                servicing = 1'b1;
                wait_low = 1'b0;
                armed = 1'b0;
            end
            F_WAIT_LOW: begin
                pending = 1'b0;
                servicing = 1'b0;
                wait_low = 1'b1;
                armed = 1'b0;
            end
            default: begin end
        endcase
    end
endmodule

module interrupt_0004_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire irq0,
    input  wire irq1,
    input  wire ack,
    output reg  busy,
    output reg  high_active,
    output reg  low_active
);
    localparam [1:0] F_IDLE         = 2'd0;
    localparam [1:0] F_HIGH         = 2'd1;
    localparam [1:0] F_LOW          = 2'd2;

    reg [1:0] state, next_state;

    wire guard_idle_0 = (irq0);
    wire guard_idle_1 = (irq1);
    wire guard_high_0 = (ack && irq1);
    wire guard_high_1 = (ack);
    wire guard_low_0 = (irq0);
    wire guard_low_1 = (ack);

    always @* begin
        next_state = state;
        case (state)
            F_IDLE: begin
                if (guard_idle_0)
                    next_state = F_HIGH;
                else if (guard_idle_1)
                    next_state = F_LOW;
                else
                    next_state = F_IDLE;
            end
            F_HIGH: begin
                if (guard_high_0)
                    next_state = F_LOW;
                else if (guard_high_1)
                    next_state = F_IDLE;
                else
                    next_state = F_HIGH;
            end
            F_LOW: begin
                if (guard_low_0)
                    next_state = F_HIGH;
                else if (guard_low_1)
                    next_state = F_IDLE;
                else
                    next_state = F_LOW;
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
        busy = 1'b0;
        high_active = 1'b0;
        low_active = 1'b0;
        case (state)
            F_IDLE: begin
                busy = 1'b0;
                high_active = 1'b0;
                low_active = 1'b0;
            end
            F_HIGH: begin
                busy = 1'b1;
                high_active = 1'b1;
                low_active = 1'b0;
            end
            F_LOW: begin
                busy = 1'b1;
                high_active = 1'b0;
                low_active = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

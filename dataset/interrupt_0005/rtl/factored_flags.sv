module interrupt_0005_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire irq,
    input  wire accept,
    input  wire done,
    output reg  pending,
    output reg  busy,
    output reg  cooldown
);
    localparam [1:0] F_IDLE         = 2'd0;
    localparam [1:0] F_PENDING      = 2'd1;
    localparam [1:0] F_SERVICE      = 2'd2;
    localparam [1:0] F_COOLDOWN     = 2'd3;

    reg [1:0] state, next_state;

    wire guard_idle_0 = (irq);
    wire guard_idle_1 = (!irq);
    wire guard_pending_0 = (accept);
    wire guard_pending_1 = (!accept);
    wire guard_service_0 = (done);
    wire guard_service_1 = (!done);
    wire guard_cooldown_0 = (!irq);
    wire guard_cooldown_1 = (irq);

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
                if (guard_service_0)
                    next_state = F_COOLDOWN;
                else if (guard_service_1)
                    next_state = F_SERVICE;
            end
            F_COOLDOWN: begin
                if (guard_cooldown_0)
                    next_state = F_IDLE;
                else if (guard_cooldown_1)
                    next_state = F_COOLDOWN;
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
        busy = 1'b0;
        cooldown = 1'b0;
        case (state)
            F_IDLE: begin
                pending = 1'b0;
                busy = 1'b0;
                cooldown = 1'b0;
            end
            F_PENDING: begin
                pending = 1'b1;
                busy = 1'b0;
                cooldown = 1'b0;
            end
            F_SERVICE: begin
                pending = 1'b0;
                busy = 1'b1;
                cooldown = 1'b0;
            end
            F_COOLDOWN: begin
                pending = 1'b0;
                busy = 1'b0;
                cooldown = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

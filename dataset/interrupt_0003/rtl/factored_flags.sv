module interrupt_0003_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire irq0,
    input  wire irq1,
    input  wire mask0,
    input  wire mask1,
    input  wire ack,
    output reg  busy,
    output reg  service0,
    output reg  service1
);
    localparam [1:0] F_IDLE         = 2'd0;
    localparam [1:0] F_SERVE0       = 2'd1;
    localparam [1:0] F_SERVE1       = 2'd2;

    reg [1:0] state, next_state;

    wire guard_idle_0 = (irq0 && !mask0);
    wire guard_idle_1 = (irq1 && !mask1);
    wire guard_serve0_0 = (ack);
    wire guard_serve1_0 = (ack);

    always @* begin
        next_state = state;
        case (state)
            F_IDLE: begin
                if (guard_idle_0)
                    next_state = F_SERVE0;
                else if (guard_idle_1)
                    next_state = F_SERVE1;
                else
                    next_state = F_IDLE;
            end
            F_SERVE0: begin
                if (guard_serve0_0)
                    next_state = F_IDLE;
                else
                    next_state = F_SERVE0;
            end
            F_SERVE1: begin
                if (guard_serve1_0)
                    next_state = F_IDLE;
                else
                    next_state = F_SERVE1;
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
        service0 = 1'b0;
        service1 = 1'b0;
        case (state)
            F_IDLE: begin
                busy = 1'b0;
                service0 = 1'b0;
                service1 = 1'b0;
            end
            F_SERVE0: begin
                busy = 1'b1;
                service0 = 1'b1;
                service1 = 1'b0;
            end
            F_SERVE1: begin
                busy = 1'b1;
                service0 = 1'b0;
                service1 = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

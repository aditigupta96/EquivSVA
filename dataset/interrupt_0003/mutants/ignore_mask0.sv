module interrupt_0003_mutant_ignore_mask0 (
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
    localparam [1:0] IDLE  = 2'd0;
    localparam [1:0] SERVE0 = 2'd1;
    localparam [1:0] SERVE1 = 2'd2;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            IDLE: next_state = (irq0) ? SERVE0 : ((irq1 && !mask1) ? SERVE1 : (IDLE));
            SERVE0: next_state = (ack) ? IDLE : (SERVE0);
            SERVE1: next_state = (ack) ? IDLE : (SERVE1);
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
        busy = 1'b0;
        service0 = 1'b0;
        service1 = 1'b0;
        case (state)
            IDLE: begin
                busy = 1'b0;
                service0 = 1'b0;
                service1 = 1'b0;
            end
            SERVE0: begin
                busy = 1'b1;
                service0 = 1'b1;
                service1 = 1'b0;
            end
            SERVE1: begin
                busy = 1'b1;
                service0 = 1'b0;
                service1 = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

module interrupt_0004_mutant_no_preemption (
    input  wire clk,
    input  wire rst,
    input  wire irq0,
    input  wire irq1,
    input  wire ack,
    output reg  busy,
    output reg  high_active,
    output reg  low_active
);
    localparam [1:0] IDLE  = 2'd0;
    localparam [1:0] HIGH  = 2'd1;
    localparam [1:0] LOW   = 2'd2;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            IDLE: next_state = (irq0) ? HIGH : ((irq1) ? LOW : (IDLE));
            HIGH: next_state = (ack && irq1) ? LOW : ((ack) ? IDLE : (HIGH));
            LOW: next_state = (ack) ? IDLE : (LOW);
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
        high_active = 1'b0;
        low_active = 1'b0;
        case (state)
            IDLE: begin
                busy = 1'b0;
                high_active = 1'b0;
                low_active = 1'b0;
            end
            HIGH: begin
                busy = 1'b1;
                high_active = 1'b1;
                low_active = 1'b0;
            end
            LOW: begin
                busy = 1'b1;
                high_active = 1'b0;
                low_active = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

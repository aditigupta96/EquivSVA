module interrupt_0008_mutant_drop_t3 (
    input  wire clk,
    input  wire rst,
    input  wire irq_hi,
    input  wire irq_lo,
    input  wire ack,
    output reg  low_pending,
    output reg  high_pending,
    output reg  service
);
    localparam [1:0] IDLE  = 2'd0;
    localparam [1:0] LOW   = 2'd1;
    localparam [1:0] HIGH  = 2'd2;
    localparam [1:0] SERVICE = 2'd3;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            IDLE: next_state = (irq_hi) ? HIGH : ((!irq_hi && irq_lo) ? LOW : (IDLE));
            LOW: next_state = (irq_hi) ? HIGH : ((!irq_hi && ack) ? SERVICE : ((!irq_hi && !ack) ? LOW : (LOW)));
            HIGH: next_state = (ack) ? SERVICE : ((!ack) ? HIGH : (HIGH));
            SERVICE: next_state = IDLE;
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
        low_pending = 1'b0;
        high_pending = 1'b0;
        service = 1'b0;
        case (state)
            IDLE: begin
                low_pending = 1'b0;
                high_pending = 1'b0;
                service = 1'b0;
            end
            LOW: begin
                low_pending = 1'b1;
                high_pending = 1'b0;
                service = 1'b0;
            end
            HIGH: begin
                low_pending = 1'b0;
                high_pending = 1'b1;
                service = 1'b0;
            end
            SERVICE: begin
                low_pending = 1'b0;
                high_pending = 1'b0;
                service = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

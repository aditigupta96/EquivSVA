module interrupt_0008_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire irq_hi,
    input  wire irq_lo,
    input  wire ack,
    output reg  low_pending,
    output reg  high_pending,
    output reg  service
);
    localparam [3:0] IDLE  = 4'b0001;
    localparam [3:0] LOW   = 4'b0010;
    localparam [3:0] HIGH  = 4'b0100;
    localparam [3:0] SERVICE = 4'b1000;

    reg [3:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (irq_hi) ? HIGH : ((!irq_hi && irq_lo) ? LOW : ((!irq_hi && !irq_lo) ? IDLE : (IDLE)));
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
        low_pending = (state == LOW);
        high_pending = (state == HIGH);
        service = (state == SERVICE);
    end
endmodule

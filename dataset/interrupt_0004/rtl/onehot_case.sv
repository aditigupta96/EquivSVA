module interrupt_0004_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire irq0,
    input  wire irq1,
    input  wire ack,
    output reg  busy,
    output reg  high_active,
    output reg  low_active
);
    localparam [2:0] IDLE  = 3'b001;
    localparam [2:0] HIGH  = 3'b010;
    localparam [2:0] LOW   = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (irq0) ? HIGH : ((irq1) ? LOW : (IDLE));
            HIGH: next_state = (ack && irq1) ? LOW : ((ack) ? IDLE : (HIGH));
            LOW: next_state = (irq0) ? HIGH : ((ack) ? IDLE : (LOW));
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
        busy = (state == HIGH) || (state == LOW);
        high_active = (state == HIGH);
        low_active = (state == LOW);
    end
endmodule

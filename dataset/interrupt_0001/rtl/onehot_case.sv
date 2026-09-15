module interrupt_0001_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire irq,
    input  wire ack,
    output reg  pending
);
    localparam [1:0] IDLE  = 2'b01;
    localparam [1:0] PENDING = 2'b10;

    reg [1:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (irq) ? PENDING : ((!irq) ? IDLE : (IDLE));
            PENDING: next_state = (ack) ? IDLE : ((!ack) ? PENDING : (PENDING));
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
        pending = (state == PENDING);
    end
endmodule

module interrupt_0006_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire irq,
    input  wire mask,
    input  wire ack,
    output reg  pending,
    output reg  servicing
);
    localparam [2:0] IDLE  = 3'b001;
    localparam [2:0] PENDING = 3'b010;
    localparam [2:0] SERVICE = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (irq && !mask) ? PENDING : ((!(irq && !mask)) ? IDLE : (IDLE));
            PENDING: next_state = (ack) ? SERVICE : ((!ack) ? PENDING : (PENDING));
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
        pending = (state == PENDING);
        servicing = (state == SERVICE);
    end
endmodule

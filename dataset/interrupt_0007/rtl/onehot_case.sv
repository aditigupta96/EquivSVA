module interrupt_0007_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire irq,
    input  wire mask,
    input  wire ack,
    output reg  pending,
    output reg  held_masked,
    output reg  servicing
);
    localparam [3:0] IDLE  = 4'b0001;
    localparam [3:0] PENDING = 4'b0010;
    localparam [3:0] HELD  = 4'b0100;
    localparam [3:0] SERVICE = 4'b1000;

    reg [3:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (irq && !mask) ? PENDING : ((!(irq && !mask)) ? IDLE : (IDLE));
            PENDING: next_state = (mask) ? HELD : ((!mask && ack) ? SERVICE : ((!mask && !ack) ? PENDING : (PENDING)));
            HELD: next_state = (mask) ? HELD : ((!mask) ? PENDING : (HELD));
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
        held_masked = (state == HELD);
        servicing = (state == SERVICE);
    end
endmodule

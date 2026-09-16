module interrupt_0007_canonical_case (
    input  wire clk,
    input  wire rst,
    input  wire irq,
    input  wire mask,
    input  wire ack,
    output reg  pending,
    output reg  held_masked,
    output reg  servicing
);
    localparam [1:0] IDLE  = 2'd0;
    localparam [1:0] PENDING = 2'd1;
    localparam [1:0] HELD  = 2'd2;
    localparam [1:0] SERVICE = 2'd3;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
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
        pending = 1'b0;
        held_masked = 1'b0;
        servicing = 1'b0;
        case (state)
            IDLE: begin
                pending = 1'b0;
                held_masked = 1'b0;
                servicing = 1'b0;
            end
            PENDING: begin
                pending = 1'b1;
                held_masked = 1'b0;
                servicing = 1'b0;
            end
            HELD: begin
                pending = 1'b0;
                held_masked = 1'b1;
                servicing = 1'b0;
            end
            SERVICE: begin
                pending = 1'b0;
                held_masked = 1'b0;
                servicing = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

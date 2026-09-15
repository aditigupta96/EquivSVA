module interrupt_0001_mutant_pending_stuck (
    input  wire clk,
    input  wire rst,
    input  wire irq,
    input  wire ack,
    output reg  pending
);
    localparam [0:0] IDLE  = 1'd0;
    localparam [0:0] PENDING = 1'd1;

    reg [0:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            IDLE: next_state = (irq) ? PENDING : ((!irq) ? IDLE : (IDLE));
            PENDING: next_state = PENDING;
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
        case (state)
            IDLE: begin
                pending = 1'b0;
            end
            PENDING: begin
                pending = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

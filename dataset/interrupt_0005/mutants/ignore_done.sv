module interrupt_0005_mutant_ignore_done (
    input  wire clk,
    input  wire rst,
    input  wire irq,
    input  wire accept,
    input  wire done,
    output reg  pending,
    output reg  busy,
    output reg  cooldown
);
    localparam [1:0] IDLE  = 2'd0;
    localparam [1:0] PENDING = 2'd1;
    localparam [1:0] SERVICE = 2'd2;
    localparam [1:0] COOLDOWN = 2'd3;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            IDLE: next_state = (irq) ? PENDING : ((!irq) ? IDLE : (IDLE));
            PENDING: next_state = (accept) ? SERVICE : ((!accept) ? PENDING : (PENDING));
            SERVICE: next_state = (!done) ? SERVICE : (SERVICE);
            COOLDOWN: next_state = (!irq) ? IDLE : ((irq) ? COOLDOWN : (COOLDOWN));
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
        busy = 1'b0;
        cooldown = 1'b0;
        case (state)
            IDLE: begin
                pending = 1'b0;
                busy = 1'b0;
                cooldown = 1'b0;
            end
            PENDING: begin
                pending = 1'b1;
                busy = 1'b0;
                cooldown = 1'b0;
            end
            SERVICE: begin
                pending = 1'b0;
                busy = 1'b1;
                cooldown = 1'b0;
            end
            COOLDOWN: begin
                pending = 1'b0;
                busy = 1'b0;
                cooldown = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

module interrupt_0009_mutant_ignore_irq (
    input  wire clk,
    input  wire rst,
    input  wire irq,
    input  wire ack,
    output reg  pending,
    output reg  servicing,
    output reg  wait_low,
    output reg  armed
);
    localparam [1:0] ARMED = 2'd0;
    localparam [1:0] PENDING = 2'd1;
    localparam [1:0] SERVICE = 2'd2;
    localparam [1:0] WAIT_LOW = 2'd3;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            ARMED: next_state = (!irq) ? ARMED : (ARMED);
            PENDING: next_state = (ack) ? SERVICE : ((!ack) ? PENDING : (PENDING));
            SERVICE: next_state = WAIT_LOW;
            WAIT_LOW: next_state = (irq) ? WAIT_LOW : ((!irq) ? ARMED : (WAIT_LOW));
            default: next_state = ARMED;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= ARMED;
        else
            state <= next_state;
    end

    always @* begin
        pending = 1'b0;
        servicing = 1'b0;
        wait_low = 1'b0;
        armed = 1'b0;
        case (state)
            ARMED: begin
                pending = 1'b0;
                servicing = 1'b0;
                wait_low = 1'b0;
                armed = 1'b1;
            end
            PENDING: begin
                pending = 1'b1;
                servicing = 1'b0;
                wait_low = 1'b0;
                armed = 1'b0;
            end
            SERVICE: begin
                pending = 1'b0;
                servicing = 1'b1;
                wait_low = 1'b0;
                armed = 1'b0;
            end
            WAIT_LOW: begin
                pending = 1'b0;
                servicing = 1'b0;
                wait_low = 1'b1;
                armed = 1'b0;
            end
            default: begin end
        endcase
    end
endmodule

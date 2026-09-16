module interrupt_0009_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire irq,
    input  wire ack,
    output reg  pending,
    output reg  servicing,
    output reg  wait_low,
    output reg  armed
);
    localparam [3:0] ARMED = 4'b0001;
    localparam [3:0] PENDING = 4'b0010;
    localparam [3:0] SERVICE = 4'b0100;
    localparam [3:0] WAIT_LOW = 4'b1000;

    reg [3:0] state, next_state;

    always @* begin
        next_state = ARMED;
        case (state)
            ARMED: next_state = (irq) ? PENDING : ((!irq) ? ARMED : (ARMED));
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
        pending = (state == PENDING);
        servicing = (state == SERVICE);
        wait_low = (state == WAIT_LOW);
        armed = (state == ARMED);
    end
endmodule

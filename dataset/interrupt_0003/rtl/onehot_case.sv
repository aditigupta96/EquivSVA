module interrupt_0003_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire irq0,
    input  wire irq1,
    input  wire mask0,
    input  wire mask1,
    input  wire ack,
    output reg  busy,
    output reg  service0,
    output reg  service1
);
    localparam [2:0] IDLE  = 3'b001;
    localparam [2:0] SERVE0 = 3'b010;
    localparam [2:0] SERVE1 = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (irq0 && !mask0) ? SERVE0 : ((irq1 && !mask1) ? SERVE1 : (IDLE));
            SERVE0: next_state = (ack) ? IDLE : (SERVE0);
            SERVE1: next_state = (ack) ? IDLE : (SERVE1);
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
        busy = (state == SERVE0) || (state == SERVE1);
        service0 = (state == SERVE0);
        service1 = (state == SERVE1);
    end
endmodule

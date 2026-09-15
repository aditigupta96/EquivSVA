module interrupt_0005_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire irq,
    input  wire accept,
    input  wire done,
    output reg  pending,
    output reg  busy,
    output reg  cooldown
);
    localparam [3:0] IDLE  = 4'b0001;
    localparam [3:0] PENDING = 4'b0010;
    localparam [3:0] SERVICE = 4'b0100;
    localparam [3:0] COOLDOWN = 4'b1000;

    reg [3:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (irq) ? PENDING : ((!irq) ? IDLE : (IDLE));
            PENDING: next_state = (accept) ? SERVICE : ((!accept) ? PENDING : (PENDING));
            SERVICE: next_state = (done) ? COOLDOWN : ((!done) ? SERVICE : (SERVICE));
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
        pending = (state == PENDING);
        busy = (state == SERVICE);
        cooldown = (state == COOLDOWN);
    end
endmodule

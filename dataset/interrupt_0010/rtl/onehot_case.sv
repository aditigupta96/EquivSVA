module interrupt_0010_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire irq,
    input  wire cancel,
    input  wire ack,
    output reg  pending,
    output reg  service,
    output reg  cancelled
);
    localparam [3:0] IDLE  = 4'b0001;
    localparam [3:0] PENDING = 4'b0010;
    localparam [3:0] SERVICE = 4'b0100;
    localparam [3:0] CANCEL = 4'b1000;

    reg [3:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (irq) ? PENDING : ((!irq) ? IDLE : (IDLE));
            PENDING: next_state = (cancel) ? CANCEL : ((!cancel && ack) ? SERVICE : ((!cancel && !ack) ? PENDING : (PENDING)));
            SERVICE: next_state = IDLE;
            CANCEL: next_state = IDLE;
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
        service = (state == SERVICE);
        cancelled = (state == CANCEL);
    end
endmodule

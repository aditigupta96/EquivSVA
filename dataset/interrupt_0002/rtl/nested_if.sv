module interrupt_0002_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire irq,
    input  wire mask,
    input  wire ack,
    output wire pending
);
    localparam [0:0] S_IDLE   = 1'd0;
    localparam [0:0] S_PENDING = 1'd1;

    reg [0:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (irq && !mask) ? S_PENDING : (S_IDLE);
            end
            else if (state == S_PENDING) begin
                state <= (ack) ? S_IDLE : (S_PENDING);
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign pending = (state == S_PENDING);
endmodule

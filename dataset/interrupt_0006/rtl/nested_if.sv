module interrupt_0006_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire irq,
    input  wire mask,
    input  wire ack,
    output wire pending,
    output wire servicing
);
    localparam [1:0] S_IDLE   = 2'd0;
    localparam [1:0] S_PENDING = 2'd1;
    localparam [1:0] S_SERVICE = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (irq && !mask) ? S_PENDING : ((!(irq && !mask)) ? S_IDLE : (S_IDLE));
            end
            else if (state == S_PENDING) begin
                state <= (ack) ? S_SERVICE : ((!ack) ? S_PENDING : (S_PENDING));
            end
            else if (state == S_SERVICE) begin
                state <= S_IDLE;
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign pending = (state == S_PENDING);
    assign servicing = (state == S_SERVICE);
endmodule

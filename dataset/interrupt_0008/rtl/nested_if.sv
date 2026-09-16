module interrupt_0008_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire irq_hi,
    input  wire irq_lo,
    input  wire ack,
    output wire low_pending,
    output wire high_pending,
    output wire service
);
    localparam [1:0] S_IDLE   = 2'd0;
    localparam [1:0] S_LOW    = 2'd1;
    localparam [1:0] S_HIGH   = 2'd2;
    localparam [1:0] S_SERVICE = 2'd3;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (irq_hi) ? S_HIGH : ((!irq_hi && irq_lo) ? S_LOW : ((!irq_hi && !irq_lo) ? S_IDLE : (S_IDLE)));
            end
            else if (state == S_LOW) begin
                state <= (irq_hi) ? S_HIGH : ((!irq_hi && ack) ? S_SERVICE : ((!irq_hi && !ack) ? S_LOW : (S_LOW)));
            end
            else if (state == S_HIGH) begin
                state <= (ack) ? S_SERVICE : ((!ack) ? S_HIGH : (S_HIGH));
            end
            else if (state == S_SERVICE) begin
                state <= S_IDLE;
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign low_pending = (state == S_LOW);
    assign high_pending = (state == S_HIGH);
    assign service = (state == S_SERVICE);
endmodule

module interrupt_0010_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire irq,
    input  wire cancel,
    input  wire ack,
    output wire pending,
    output wire service,
    output wire cancelled
);
    localparam [1:0] S_IDLE   = 2'd0;
    localparam [1:0] S_PENDING = 2'd1;
    localparam [1:0] S_SERVICE = 2'd2;
    localparam [1:0] S_CANCEL = 2'd3;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (irq) ? S_PENDING : ((!irq) ? S_IDLE : (S_IDLE));
            end
            else if (state == S_PENDING) begin
                state <= (cancel) ? S_CANCEL : ((!cancel && ack) ? S_SERVICE : ((!cancel && !ack) ? S_PENDING : (S_PENDING)));
            end
            else if (state == S_SERVICE) begin
                state <= S_IDLE;
            end
            else if (state == S_CANCEL) begin
                state <= S_IDLE;
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign pending = (state == S_PENDING);
    assign service = (state == S_SERVICE);
    assign cancelled = (state == S_CANCEL);
endmodule

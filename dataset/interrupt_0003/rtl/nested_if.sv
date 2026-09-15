module interrupt_0003_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire irq0,
    input  wire irq1,
    input  wire mask0,
    input  wire mask1,
    input  wire ack,
    output wire busy,
    output wire service0,
    output wire service1
);
    localparam [1:0] S_IDLE   = 2'd0;
    localparam [1:0] S_SERVE0 = 2'd1;
    localparam [1:0] S_SERVE1 = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (irq0 && !mask0) ? S_SERVE0 : ((irq1 && !mask1) ? S_SERVE1 : (S_IDLE));
            end
            else if (state == S_SERVE0) begin
                state <= (ack) ? S_IDLE : (S_SERVE0);
            end
            else if (state == S_SERVE1) begin
                state <= (ack) ? S_IDLE : (S_SERVE1);
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign busy = (state == S_SERVE0) || (state == S_SERVE1);
    assign service0 = (state == S_SERVE0);
    assign service1 = (state == S_SERVE1);
endmodule

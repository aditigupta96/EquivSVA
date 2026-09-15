module interrupt_0005_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire irq,
    input  wire accept,
    input  wire done,
    output wire pending,
    output wire busy,
    output wire cooldown
);
    localparam [1:0] S_IDLE   = 2'd0;
    localparam [1:0] S_PENDING = 2'd1;
    localparam [1:0] S_SERVICE = 2'd2;
    localparam [1:0] S_COOLDOWN = 2'd3;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (irq) ? S_PENDING : ((!irq) ? S_IDLE : (S_IDLE));
            end
            else if (state == S_PENDING) begin
                state <= (accept) ? S_SERVICE : ((!accept) ? S_PENDING : (S_PENDING));
            end
            else if (state == S_SERVICE) begin
                state <= (done) ? S_COOLDOWN : ((!done) ? S_SERVICE : (S_SERVICE));
            end
            else if (state == S_COOLDOWN) begin
                state <= (!irq) ? S_IDLE : ((irq) ? S_COOLDOWN : (S_COOLDOWN));
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign pending = (state == S_PENDING);
    assign busy = (state == S_SERVICE);
    assign cooldown = (state == S_COOLDOWN);
endmodule

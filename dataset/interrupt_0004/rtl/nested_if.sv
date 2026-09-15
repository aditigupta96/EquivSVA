module interrupt_0004_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire irq0,
    input  wire irq1,
    input  wire ack,
    output wire busy,
    output wire high_active,
    output wire low_active
);
    localparam [1:0] S_IDLE   = 2'd0;
    localparam [1:0] S_HIGH   = 2'd1;
    localparam [1:0] S_LOW    = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (irq0) ? S_HIGH : ((irq1) ? S_LOW : (S_IDLE));
            end
            else if (state == S_HIGH) begin
                state <= (ack && irq1) ? S_LOW : ((ack) ? S_IDLE : (S_HIGH));
            end
            else if (state == S_LOW) begin
                state <= (irq0) ? S_HIGH : ((ack) ? S_IDLE : (S_LOW));
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign busy = (state == S_HIGH) || (state == S_LOW);
    assign high_active = (state == S_HIGH);
    assign low_active = (state == S_LOW);
endmodule

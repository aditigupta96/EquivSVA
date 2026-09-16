module interrupt_0009_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire irq,
    input  wire ack,
    output wire pending,
    output wire servicing,
    output wire wait_low,
    output wire armed
);
    localparam [1:0] S_ARMED  = 2'd0;
    localparam [1:0] S_PENDING = 2'd1;
    localparam [1:0] S_SERVICE = 2'd2;
    localparam [1:0] S_WAIT_LOW = 2'd3;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_ARMED;
        end else begin
            if (state == S_ARMED) begin
                state <= (irq) ? S_PENDING : ((!irq) ? S_ARMED : (S_ARMED));
            end
            else if (state == S_PENDING) begin
                state <= (ack) ? S_SERVICE : ((!ack) ? S_PENDING : (S_PENDING));
            end
            else if (state == S_SERVICE) begin
                state <= S_WAIT_LOW;
            end
            else if (state == S_WAIT_LOW) begin
                state <= (irq) ? S_WAIT_LOW : ((!irq) ? S_ARMED : (S_WAIT_LOW));
            end
            else begin
                state <= S_ARMED;
            end
        end
    end

    assign pending = (state == S_PENDING);
    assign servicing = (state == S_SERVICE);
    assign wait_low = (state == S_WAIT_LOW);
    assign armed = (state == S_ARMED);
endmodule

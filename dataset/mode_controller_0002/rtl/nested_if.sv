module mode_controller_0002_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire enable,
    input  wire sleep,
    input  wire wake,
    output wire active,
    output wire sleeping,
    output wire off
);
    localparam [1:0] S_OFF    = 2'd0;
    localparam [1:0] S_ACTIVE = 2'd1;
    localparam [1:0] S_SLEEP  = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_OFF;
        end else begin
            if (state == S_OFF) begin
                state <= (enable) ? S_ACTIVE : ((!enable) ? S_OFF : (S_OFF));
            end
            else if (state == S_ACTIVE) begin
                state <= (!enable) ? S_OFF : ((enable && sleep) ? S_SLEEP : ((enable && !sleep) ? S_ACTIVE : (S_ACTIVE)));
            end
            else if (state == S_SLEEP) begin
                state <= (!enable) ? S_OFF : ((enable && wake) ? S_ACTIVE : ((enable && !wake) ? S_SLEEP : (S_SLEEP)));
            end
            else begin
                state <= S_OFF;
            end
        end
    end

    assign active = (state == S_ACTIVE);
    assign sleeping = (state == S_SLEEP);
    assign off = (state == S_OFF);
endmodule

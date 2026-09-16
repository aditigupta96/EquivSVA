module timer_0006_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire tick,
    input  wire kick,
    output wire armed,
    output wire warning,
    output wire timeout
);
    localparam [1:0] S_ARMED  = 2'd0;
    localparam [1:0] S_WARN   = 2'd1;
    localparam [1:0] S_TIMEOUT = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_ARMED;
        end else begin
            if (state == S_ARMED) begin
                state <= (kick) ? S_ARMED : ((!kick && tick) ? S_WARN : ((!kick && !tick) ? S_ARMED : (S_ARMED)));
            end
            else if (state == S_WARN) begin
                state <= (kick) ? S_ARMED : ((!kick && tick) ? S_TIMEOUT : ((!kick && !tick) ? S_WARN : (S_WARN)));
            end
            else if (state == S_TIMEOUT) begin
                state <= (kick) ? S_ARMED : ((!kick) ? S_TIMEOUT : (S_TIMEOUT));
            end
            else begin
                state <= S_ARMED;
            end
        end
    end

    assign armed = (state == S_ARMED);
    assign warning = (state == S_WARN);
    assign timeout = (state == S_TIMEOUT);
endmodule

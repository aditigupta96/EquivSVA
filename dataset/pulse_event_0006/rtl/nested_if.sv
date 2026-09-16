module pulse_event_0006_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire trigger,
    input  wire cancel,
    output wire armed,
    output wire pulse,
    output wire cancelled
);
    localparam [1:0] S_ARMED  = 2'd0;
    localparam [1:0] S_PULSE  = 2'd1;
    localparam [1:0] S_CANCEL = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_ARMED;
        end else begin
            if (state == S_ARMED) begin
                state <= (trigger && !cancel) ? S_PULSE : ((cancel) ? S_CANCEL : ((!trigger && !cancel) ? S_ARMED : (S_ARMED)));
            end
            else if (state == S_PULSE) begin
                state <= S_ARMED;
            end
            else if (state == S_CANCEL) begin
                state <= S_ARMED;
            end
            else begin
                state <= S_ARMED;
            end
        end
    end

    assign armed = (state == S_ARMED);
    assign pulse = (state == S_PULSE);
    assign cancelled = (state == S_CANCEL);
endmodule

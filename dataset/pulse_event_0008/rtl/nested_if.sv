module pulse_event_0008_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire trigger,
    input  wire enable,
    output wire armed,
    output wire pulse,
    output wire disabled
);
    localparam [1:0] S_DISABLED = 2'd0;
    localparam [1:0] S_ARMED  = 2'd1;
    localparam [1:0] S_PULSE  = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_DISABLED;
        end else begin
            if (state == S_DISABLED) begin
                state <= (enable) ? S_ARMED : ((!enable) ? S_DISABLED : (S_DISABLED));
            end
            else if (state == S_ARMED) begin
                state <= (!enable) ? S_DISABLED : ((enable && trigger) ? S_PULSE : ((enable && !trigger) ? S_ARMED : (S_ARMED)));
            end
            else if (state == S_PULSE) begin
                state <= (enable) ? S_ARMED : ((!enable) ? S_DISABLED : (S_PULSE));
            end
            else begin
                state <= S_DISABLED;
            end
        end
    end

    assign armed = (state == S_ARMED);
    assign pulse = (state == S_PULSE);
    assign disabled = (state == S_DISABLED);
endmodule

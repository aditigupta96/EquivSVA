module pulse_event_0004_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire trigger,
    input  wire clear,
    output wire armed,
    output wire pulse,
    output wire latched
);
    localparam [1:0] S_ARMED  = 2'd0;
    localparam [1:0] S_PULSE  = 2'd1;
    localparam [1:0] S_LATCHED = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_ARMED;
        end else begin
            if (state == S_ARMED) begin
                state <= (trigger) ? S_PULSE : ((!trigger) ? S_ARMED : (S_ARMED));
            end
            else if (state == S_PULSE) begin
                state <= S_LATCHED;
            end
            else if (state == S_LATCHED) begin
                state <= (clear) ? S_ARMED : ((!clear) ? S_LATCHED : (S_LATCHED));
            end
            else begin
                state <= S_ARMED;
            end
        end
    end

    assign armed = (state == S_ARMED);
    assign pulse = (state == S_PULSE);
    assign latched = (state == S_LATCHED);
endmodule

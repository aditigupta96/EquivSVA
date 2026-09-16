module pulse_event_0005_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire event_in,
    output wire armed,
    output wire qualifying,
    output wire pulse,
    output wire rearming
);
    localparam [2:0] S_ARMED  = 3'd0;
    localparam [2:0] S_HIGH1  = 3'd1;
    localparam [2:0] S_PULSE  = 3'd2;
    localparam [2:0] S_WAIT_LOW = 3'd3;
    localparam [2:0] S_LOW1   = 3'd4;

    reg [2:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_ARMED;
        end else begin
            if (state == S_ARMED) begin
                state <= (event_in) ? S_HIGH1 : ((!event_in) ? S_ARMED : (S_ARMED));
            end
            else if (state == S_HIGH1) begin
                state <= (event_in) ? S_PULSE : ((!event_in) ? S_ARMED : (S_HIGH1));
            end
            else if (state == S_PULSE) begin
                state <= S_WAIT_LOW;
            end
            else if (state == S_WAIT_LOW) begin
                state <= (!event_in) ? S_LOW1 : ((event_in) ? S_WAIT_LOW : (S_WAIT_LOW));
            end
            else if (state == S_LOW1) begin
                state <= (!event_in) ? S_ARMED : ((event_in) ? S_WAIT_LOW : (S_LOW1));
            end
            else begin
                state <= S_ARMED;
            end
        end
    end

    assign armed = (state == S_ARMED);
    assign qualifying = (state == S_HIGH1);
    assign pulse = (state == S_PULSE);
    assign rearming = (state == S_WAIT_LOW) || (state == S_LOW1);
endmodule

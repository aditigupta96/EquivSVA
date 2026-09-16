module pulse_event_0002_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire event_in,
    output wire armed,
    output wire pulse,
    output wire blocked
);
    localparam [1:0] S_ARMED  = 2'd0;
    localparam [1:0] S_PULSE  = 2'd1;
    localparam [1:0] S_BLOCKED = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_ARMED;
        end else begin
            if (state == S_ARMED) begin
                state <= (event_in) ? S_PULSE : ((!event_in) ? S_ARMED : (S_ARMED));
            end
            else if (state == S_PULSE) begin
                state <= S_BLOCKED;
            end
            else if (state == S_BLOCKED) begin
                state <= (event_in) ? S_BLOCKED : ((!event_in) ? S_ARMED : (S_BLOCKED));
            end
            else begin
                state <= S_ARMED;
            end
        end
    end

    assign armed = (state == S_ARMED);
    assign pulse = (state == S_PULSE);
    assign blocked = (state == S_BLOCKED);
endmodule

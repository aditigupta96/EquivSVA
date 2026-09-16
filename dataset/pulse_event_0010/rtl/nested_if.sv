module pulse_event_0010_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire arm,
    input  wire trigger,
    input  wire rearm,
    output wire disarmed,
    output wire armed,
    output wire pulse,
    output wire spent
);
    localparam [1:0] S_DISARMED = 2'd0;
    localparam [1:0] S_ARMED  = 2'd1;
    localparam [1:0] S_PULSE  = 2'd2;
    localparam [1:0] S_SPENT  = 2'd3;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_DISARMED;
        end else begin
            if (state == S_DISARMED) begin
                state <= (arm) ? S_ARMED : ((!arm) ? S_DISARMED : (S_DISARMED));
            end
            else if (state == S_ARMED) begin
                state <= (trigger) ? S_PULSE : ((!trigger) ? S_ARMED : (S_ARMED));
            end
            else if (state == S_PULSE) begin
                state <= S_SPENT;
            end
            else if (state == S_SPENT) begin
                state <= (rearm) ? S_ARMED : ((!rearm) ? S_SPENT : (S_SPENT));
            end
            else begin
                state <= S_DISARMED;
            end
        end
    end

    assign disarmed = (state == S_DISARMED);
    assign armed = (state == S_ARMED);
    assign pulse = (state == S_PULSE);
    assign spent = (state == S_SPENT);
endmodule

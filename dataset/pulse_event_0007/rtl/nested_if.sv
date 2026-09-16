module pulse_event_0007_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire trigger,
    output wire armed,
    output wire pulse,
    output wire cooldown
);
    localparam [1:0] S_ARMED  = 2'd0;
    localparam [1:0] S_PULSE  = 2'd1;
    localparam [1:0] S_COOL1  = 2'd2;
    localparam [1:0] S_COOL2  = 2'd3;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_ARMED;
        end else begin
            if (state == S_ARMED) begin
                state <= (trigger) ? S_PULSE : ((!trigger) ? S_ARMED : (S_ARMED));
            end
            else if (state == S_PULSE) begin
                state <= S_COOL1;
            end
            else if (state == S_COOL1) begin
                state <= S_COOL2;
            end
            else if (state == S_COOL2) begin
                state <= S_ARMED;
            end
            else begin
                state <= S_ARMED;
            end
        end
    end

    assign armed = (state == S_ARMED);
    assign pulse = (state == S_PULSE);
    assign cooldown = (state == S_COOL1) || (state == S_COOL2);
endmodule

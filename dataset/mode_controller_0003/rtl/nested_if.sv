module mode_controller_0003_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire enable,
    input  wire maintenance,
    input  wire exit_maintenance,
    output wire normal,
    output wire maint,
    output wire off
);
    localparam [1:0] S_OFF    = 2'd0;
    localparam [1:0] S_NORMAL = 2'd1;
    localparam [1:0] S_MAINT  = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_OFF;
        end else begin
            if (state == S_OFF) begin
                state <= (enable) ? S_NORMAL : ((!enable) ? S_OFF : (S_OFF));
            end
            else if (state == S_NORMAL) begin
                state <= (maintenance) ? S_MAINT : ((!maintenance && !enable) ? S_OFF : ((!maintenance && enable) ? S_NORMAL : (S_NORMAL)));
            end
            else if (state == S_MAINT) begin
                state <= (exit_maintenance) ? S_NORMAL : ((!exit_maintenance) ? S_MAINT : (S_MAINT));
            end
            else begin
                state <= S_OFF;
            end
        end
    end

    assign normal = (state == S_NORMAL);
    assign maint = (state == S_MAINT);
    assign off = (state == S_OFF);
endmodule

module mode_controller_0009_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire enable,
    input  wire fail,
    input  wire recover,
    output wire primary,
    output wire backup,
    output wire off
);
    localparam [1:0] S_OFF    = 2'd0;
    localparam [1:0] S_PRIMARY = 2'd1;
    localparam [1:0] S_BACKUP = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_OFF;
        end else begin
            if (state == S_OFF) begin
                state <= (enable) ? S_PRIMARY : ((!enable) ? S_OFF : (S_OFF));
            end
            else if (state == S_PRIMARY) begin
                state <= (fail) ? S_BACKUP : ((!fail && enable) ? S_PRIMARY : ((!fail && !enable) ? S_OFF : (S_PRIMARY)));
            end
            else if (state == S_BACKUP) begin
                state <= (recover) ? S_PRIMARY : ((!recover && enable) ? S_BACKUP : ((!recover && !enable) ? S_OFF : (S_BACKUP)));
            end
            else begin
                state <= S_OFF;
            end
        end
    end

    assign primary = (state == S_PRIMARY);
    assign backup = (state == S_BACKUP);
    assign off = (state == S_OFF);
endmodule

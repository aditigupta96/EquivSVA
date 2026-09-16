module mode_controller_0010_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire enable,
    input  wire auto_mode,
    input  wire disable,
    output wire manual,
    output wire automatic,
    output wire off
);
    localparam [1:0] S_OFF    = 2'd0;
    localparam [1:0] S_MANUAL = 2'd1;
    localparam [1:0] S_AUTO   = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_OFF;
        end else begin
            if (state == S_OFF) begin
                state <= (enable && auto_mode) ? S_AUTO : ((enable && !auto_mode) ? S_MANUAL : ((!enable) ? S_OFF : (S_OFF)));
            end
            else if (state == S_MANUAL) begin
                state <= (disable) ? S_OFF : ((!disable && auto_mode) ? S_AUTO : ((!disable && !auto_mode) ? S_MANUAL : (S_MANUAL)));
            end
            else if (state == S_AUTO) begin
                state <= (disable) ? S_OFF : ((!disable && !auto_mode) ? S_MANUAL : ((!disable && auto_mode) ? S_AUTO : (S_AUTO)));
            end
            else begin
                state <= S_OFF;
            end
        end
    end

    assign manual = (state == S_MANUAL);
    assign automatic = (state == S_AUTO);
    assign off = (state == S_OFF);
endmodule

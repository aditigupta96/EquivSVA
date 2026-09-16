module mode_controller_0001_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire enable,
    input  wire wake,
    input  wire fault,
    input  wire clear_fault,
    output wire standby,
    output wire active,
    output wire faulted
);
    localparam [1:0] S_OFF    = 2'd0;
    localparam [1:0] S_STANDBY = 2'd1;
    localparam [1:0] S_ACTIVE = 2'd2;
    localparam [1:0] S_FAULT  = 2'd3;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_OFF;
        end else begin
            if (state == S_OFF) begin
                state <= (enable) ? S_STANDBY : ((!enable) ? S_OFF : (S_OFF));
            end
            else if (state == S_STANDBY) begin
                state <= (fault) ? S_FAULT : ((!fault && !enable) ? S_OFF : ((!fault && enable && wake) ? S_ACTIVE : ((!fault && enable && !wake) ? S_STANDBY : (S_STANDBY))));
            end
            else if (state == S_ACTIVE) begin
                state <= (fault) ? S_FAULT : ((!fault && !enable) ? S_OFF : ((!fault && enable && !wake) ? S_STANDBY : ((!fault && enable && wake) ? S_ACTIVE : (S_ACTIVE))));
            end
            else if (state == S_FAULT) begin
                state <= (clear_fault) ? S_OFF : ((!clear_fault) ? S_FAULT : (S_FAULT));
            end
            else begin
                state <= S_OFF;
            end
        end
    end

    assign standby = (state == S_STANDBY);
    assign active = (state == S_ACTIVE);
    assign faulted = (state == S_FAULT);
endmodule

module mode_controller_0005_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire activate,
    input  wire boost,
    input  wire idle,
    output wire active,
    output wire boosted,
    output wire idle_mode
);
    localparam [1:0] S_IDLE   = 2'd0;
    localparam [1:0] S_ACTIVE = 2'd1;
    localparam [1:0] S_BOOST  = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (activate) ? S_ACTIVE : ((!activate) ? S_IDLE : (S_IDLE));
            end
            else if (state == S_ACTIVE) begin
                state <= (boost) ? S_BOOST : ((!boost && idle) ? S_IDLE : ((!boost && !idle) ? S_ACTIVE : (S_ACTIVE)));
            end
            else if (state == S_BOOST) begin
                state <= (boost) ? S_BOOST : ((!boost) ? S_ACTIVE : (S_BOOST));
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign active = (state == S_ACTIVE);
    assign boosted = (state == S_BOOST);
    assign idle_mode = (state == S_IDLE);
endmodule

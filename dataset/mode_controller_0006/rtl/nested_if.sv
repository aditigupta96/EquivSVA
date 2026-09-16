module mode_controller_0006_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire unlock,
    input  wire lock,
    input  wire operate,
    output wire locked,
    output wire ready,
    output wire active
);
    localparam [1:0] S_LOCKED = 2'd0;
    localparam [1:0] S_READY  = 2'd1;
    localparam [1:0] S_ACTIVE = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_LOCKED;
        end else begin
            if (state == S_LOCKED) begin
                state <= (unlock) ? S_READY : ((!unlock) ? S_LOCKED : (S_LOCKED));
            end
            else if (state == S_READY) begin
                state <= (lock) ? S_LOCKED : ((!lock && operate) ? S_ACTIVE : ((!lock && !operate) ? S_READY : (S_READY)));
            end
            else if (state == S_ACTIVE) begin
                state <= (lock) ? S_LOCKED : ((!lock && !operate) ? S_READY : ((!lock && operate) ? S_ACTIVE : (S_ACTIVE)));
            end
            else begin
                state <= S_LOCKED;
            end
        end
    end

    assign locked = (state == S_LOCKED);
    assign ready = (state == S_READY);
    assign active = (state == S_ACTIVE);
endmodule

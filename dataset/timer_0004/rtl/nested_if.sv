module timer_0004_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire start,
    output wire active,
    output wire tick
);
    localparam [1:0] S_IDLE   = 2'd0;
    localparam [1:0] S_RUN    = 2'd1;
    localparam [1:0] S_TICK   = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (start) ? S_RUN : (S_IDLE);
            end
            else if (state == S_RUN) begin
                state <= S_TICK;
            end
            else if (state == S_TICK) begin
                state <= S_RUN;
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign active = (state == S_RUN) || (state == S_TICK);
    assign tick = (state == S_TICK);
endmodule

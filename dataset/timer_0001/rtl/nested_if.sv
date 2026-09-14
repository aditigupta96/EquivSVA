module timer_0001_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire kick,
    output wire running,
    output wire warning,
    output wire timeout
);
    localparam [1:0] S_IDLE   = 2'd0;
    localparam [1:0] S_RUN    = 2'd1;
    localparam [1:0] S_WARNING = 2'd2;
    localparam [1:0] S_TIMEOUT = 2'd3;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (start) ? S_RUN : (S_IDLE);
            end
            else if (state == S_RUN) begin
                state <= (kick) ? S_RUN : (S_WARNING);
            end
            else if (state == S_WARNING) begin
                state <= (kick) ? S_RUN : (S_TIMEOUT);
            end
            else if (state == S_TIMEOUT) begin
                state <= S_IDLE;
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign running = (state == S_RUN) || (state == S_WARNING);
    assign warning = (state == S_WARNING);
    assign timeout = (state == S_TIMEOUT);
endmodule

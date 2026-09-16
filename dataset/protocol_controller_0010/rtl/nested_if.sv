module protocol_controller_0010_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire enable,
    input  wire quiesce,
    input  wire idle_seen,
    output wire running,
    output wire draining,
    output wire stopped
);
    localparam [1:0] S_STOP   = 2'd0;
    localparam [1:0] S_RUN    = 2'd1;
    localparam [1:0] S_DRAIN  = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_STOP;
        end else begin
            if (state == S_STOP) begin
                state <= (enable) ? S_RUN : ((!enable) ? S_STOP : (S_STOP));
            end
            else if (state == S_RUN) begin
                state <= (quiesce) ? S_DRAIN : ((!quiesce) ? S_RUN : (S_RUN));
            end
            else if (state == S_DRAIN) begin
                state <= (idle_seen) ? S_STOP : ((!idle_seen) ? S_DRAIN : (S_DRAIN));
            end
            else begin
                state <= S_STOP;
            end
        end
    end

    assign running = (state == S_RUN);
    assign draining = (state == S_DRAIN);
    assign stopped = (state == S_STOP);
endmodule

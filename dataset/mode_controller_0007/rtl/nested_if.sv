module mode_controller_0007_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire run,
    input  wire fault,
    input  wire clear,
    output wire standby,
    output wire running,
    output wire faulted
);
    localparam [1:0] S_STANDBY = 2'd0;
    localparam [1:0] S_RUN    = 2'd1;
    localparam [1:0] S_FAULT  = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_STANDBY;
        end else begin
            if (state == S_STANDBY) begin
                state <= (run) ? S_RUN : ((!run) ? S_STANDBY : (S_STANDBY));
            end
            else if (state == S_RUN) begin
                state <= (fault) ? S_FAULT : ((!fault && run) ? S_RUN : ((!fault && !run) ? S_STANDBY : (S_RUN)));
            end
            else if (state == S_FAULT) begin
                state <= (clear) ? S_STANDBY : ((!clear) ? S_FAULT : (S_FAULT));
            end
            else begin
                state <= S_STANDBY;
            end
        end
    end

    assign standby = (state == S_STANDBY);
    assign running = (state == S_RUN);
    assign faulted = (state == S_FAULT);
endmodule

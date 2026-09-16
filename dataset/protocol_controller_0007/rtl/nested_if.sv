module protocol_controller_0007_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire pause,
    input  wire resume,
    input  wire done_in,
    output wire running,
    output wire paused,
    output wire done
);
    localparam [1:0] S_IDLE   = 2'd0;
    localparam [1:0] S_RUN    = 2'd1;
    localparam [1:0] S_PAUSE  = 2'd2;
    localparam [1:0] S_DONE   = 2'd3;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (start) ? S_RUN : ((!start) ? S_IDLE : (S_IDLE));
            end
            else if (state == S_RUN) begin
                state <= (done_in) ? S_DONE : ((!done_in && pause) ? S_PAUSE : ((!done_in && !pause) ? S_RUN : (S_RUN)));
            end
            else if (state == S_PAUSE) begin
                state <= (resume) ? S_RUN : ((!resume) ? S_PAUSE : (S_PAUSE));
            end
            else if (state == S_DONE) begin
                state <= S_IDLE;
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign running = (state == S_RUN);
    assign paused = (state == S_PAUSE);
    assign done = (state == S_DONE);
endmodule

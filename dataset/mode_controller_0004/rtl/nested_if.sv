module mode_controller_0004_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire fault,
    input  wire clear,
    output wire running,
    output wire safe,
    output wire faulted
);
    localparam [1:0] S_SAFE   = 2'd0;
    localparam [1:0] S_RUN    = 2'd1;
    localparam [1:0] S_FAULT  = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_SAFE;
        end else begin
            if (state == S_SAFE) begin
                state <= (start) ? S_RUN : ((!start) ? S_SAFE : (S_SAFE));
            end
            else if (state == S_RUN) begin
                state <= (fault) ? S_FAULT : ((!fault) ? S_RUN : (S_RUN));
            end
            else if (state == S_FAULT) begin
                state <= (clear) ? S_SAFE : ((!clear) ? S_FAULT : (S_FAULT));
            end
            else begin
                state <= S_SAFE;
            end
        end
    end

    assign running = (state == S_RUN);
    assign safe = (state == S_SAFE);
    assign faulted = (state == S_FAULT);
endmodule

module mode_controller_0008_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire boot_ok,
    input  wire start,
    input  wire stop,
    output wire booting,
    output wire ready,
    output wire running
);
    localparam [1:0] S_BOOT   = 2'd0;
    localparam [1:0] S_READY  = 2'd1;
    localparam [1:0] S_RUN    = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_BOOT;
        end else begin
            if (state == S_BOOT) begin
                state <= (boot_ok) ? S_READY : ((!boot_ok) ? S_BOOT : (S_BOOT));
            end
            else if (state == S_READY) begin
                state <= (start) ? S_RUN : ((!start) ? S_READY : (S_READY));
            end
            else if (state == S_RUN) begin
                state <= (stop) ? S_READY : ((!stop) ? S_RUN : (S_RUN));
            end
            else begin
                state <= S_BOOT;
            end
        end
    end

    assign booting = (state == S_BOOT);
    assign ready = (state == S_READY);
    assign running = (state == S_RUN);
endmodule

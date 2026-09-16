module handshake_0007_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire produce,
    input  wire ready,
    output wire valid,
    output wire done
);
    localparam [1:0] S_IDLE   = 2'd0;
    localparam [1:0] S_VALID  = 2'd1;
    localparam [1:0] S_DONE   = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
        end else begin
            if (state == S_IDLE) begin
                state <= (produce) ? S_VALID : ((!produce) ? S_IDLE : (S_IDLE));
            end
            else if (state == S_VALID) begin
                state <= (ready) ? S_DONE : ((!ready) ? S_VALID : (S_VALID));
            end
            else if (state == S_DONE) begin
                state <= S_IDLE;
            end
            else begin
                state <= S_IDLE;
            end
        end
    end

    assign valid = (state == S_VALID);
    assign done = (state == S_DONE);
endmodule

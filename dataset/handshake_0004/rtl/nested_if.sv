module handshake_0004_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire push,
    input  wire ready,
    output wire valid
);
    localparam [0:0] S_EMPTY  = 1'd0;
    localparam [0:0] S_FULL   = 1'd1;

    reg [0:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_EMPTY;
        end else begin
            if (state == S_EMPTY) begin
                state <= (push) ? S_FULL : (S_EMPTY);
            end
            else if (state == S_FULL) begin
                state <= (ready) ? S_EMPTY : (S_FULL);
            end
            else begin
                state <= S_EMPTY;
            end
        end
    end

    assign valid = (state == S_FULL);
endmodule

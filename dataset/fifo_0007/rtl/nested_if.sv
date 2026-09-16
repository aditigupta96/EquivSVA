module fifo_0007_nested_if (
    input  wire clk,
    input  wire rst,
    input  wire push,
    input  wire pop,
    output wire empty,
    output wire one,
    output wire full
);
    localparam [1:0] S_EMPTY  = 2'd0;
    localparam [1:0] S_ONE    = 2'd1;
    localparam [1:0] S_FULL   = 2'd2;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_EMPTY;
        end else begin
            if (state == S_EMPTY) begin
                state <= (push) ? S_ONE : ((!push) ? S_EMPTY : (S_EMPTY));
            end
            else if (state == S_ONE) begin
                state <= (push && !pop) ? S_FULL : ((pop && !push) ? S_EMPTY : (((push && pop) || (!push && !pop)) ? S_ONE : (S_ONE)));
            end
            else if (state == S_FULL) begin
                state <= (pop) ? S_ONE : ((!pop) ? S_FULL : (S_FULL));
            end
            else begin
                state <= S_EMPTY;
            end
        end
    end

    assign empty = (state == S_EMPTY);
    assign one = (state == S_ONE);
    assign full = (state == S_FULL);
endmodule

module handshake_0007_mutant_drop_t2 (
    input  wire clk,
    input  wire rst,
    input  wire produce,
    input  wire ready,
    output reg  valid,
    output reg  done
);
    localparam [1:0] IDLE  = 2'd0;
    localparam [1:0] VALID = 2'd1;
    localparam [1:0] DONE  = 2'd2;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            IDLE: next_state = (produce) ? VALID : (IDLE);
            VALID: next_state = (ready) ? DONE : ((!ready) ? VALID : (VALID));
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @* begin
        valid = 1'b0;
        done = 1'b0;
        case (state)
            IDLE: begin
                valid = 1'b0;
                done = 1'b0;
            end
            VALID: begin
                valid = 1'b1;
                done = 1'b0;
            end
            DONE: begin
                valid = 1'b0;
                done = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

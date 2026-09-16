module handshake_0007_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire produce,
    input  wire ready,
    output reg  valid,
    output reg  done
);
    localparam [2:0] IDLE  = 3'b001;
    localparam [2:0] VALID = 3'b010;
    localparam [2:0] DONE  = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (produce) ? VALID : ((!produce) ? IDLE : (IDLE));
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
        valid = (state == VALID);
        done = (state == DONE);
    end
endmodule

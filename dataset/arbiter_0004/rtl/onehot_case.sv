module arbiter_0004_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire req0,
    input  wire req1,
    output reg  grant0,
    output reg  grant1
);
    localparam [2:0] IDLE  = 3'b001;
    localparam [2:0] GRANT0 = 3'b010;
    localparam [2:0] GRANT1 = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (req0) ? GRANT0 : ((req1) ? GRANT1 : (IDLE));
            GRANT0: next_state = (req1) ? GRANT1 : ((req0) ? GRANT0 : (IDLE));
            GRANT1: next_state = (req0) ? GRANT0 : ((req1) ? GRANT1 : (IDLE));
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
        grant0 = (state == GRANT0);
        grant1 = (state == GRANT1);
    end
endmodule

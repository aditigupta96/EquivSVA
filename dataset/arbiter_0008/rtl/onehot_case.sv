module arbiter_0008_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire req0,
    input  wire req1,
    input  wire req2,
    output reg  grant0,
    output reg  grant1,
    output reg  grant2
);
    localparam [3:0] IDLE  = 4'b0001;
    localparam [3:0] G0    = 4'b0010;
    localparam [3:0] G1    = 4'b0100;
    localparam [3:0] G2    = 4'b1000;

    reg [3:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (req0) ? G0 : ((!req0 && req1) ? G1 : ((!req0 && !req1 && req2) ? G2 : ((!req0 && !req1 && !req2) ? IDLE : (IDLE))));
            G0: next_state = IDLE;
            G1: next_state = IDLE;
            G2: next_state = IDLE;
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
        grant0 = (state == G0);
        grant1 = (state == G1);
        grant2 = (state == G2);
    end
endmodule

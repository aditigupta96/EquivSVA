module arbiter_0005_onehot_case (
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
    localparam [3:0] GRANT0 = 4'b0010;
    localparam [3:0] GRANT1 = 4'b0100;
    localparam [3:0] GRANT2 = 4'b1000;

    reg [3:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (req0) ? GRANT0 : ((req1) ? GRANT1 : ((req2) ? GRANT2 : (IDLE)));
            GRANT0: next_state = IDLE;
            GRANT1: next_state = IDLE;
            GRANT2: next_state = IDLE;
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
        grant2 = (state == GRANT2);
    end
endmodule

module arbiter_0006_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire req0,
    input  wire req1,
    input  wire release,
    output reg  grant0,
    output reg  grant1
);
    localparam [2:0] IDLE  = 3'b001;
    localparam [2:0] G0    = 3'b010;
    localparam [2:0] G1    = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (req0) ? G0 : ((!req0 && req1) ? G1 : ((!req0 && !req1) ? IDLE : (IDLE)));
            G0: next_state = (release) ? IDLE : ((!release) ? G0 : (G0));
            G1: next_state = (release) ? IDLE : ((!release) ? G1 : (G1));
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
    end
endmodule

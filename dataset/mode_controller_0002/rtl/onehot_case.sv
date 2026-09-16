module mode_controller_0002_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire enable,
    input  wire sleep,
    input  wire wake,
    output reg  active,
    output reg  sleeping,
    output reg  off
);
    localparam [2:0] OFF   = 3'b001;
    localparam [2:0] ACTIVE = 3'b010;
    localparam [2:0] SLEEP = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = OFF;
        case (state)
            OFF: next_state = (enable) ? ACTIVE : ((!enable) ? OFF : (OFF));
            ACTIVE: next_state = (!enable) ? OFF : ((enable && sleep) ? SLEEP : ((enable && !sleep) ? ACTIVE : (ACTIVE)));
            SLEEP: next_state = (!enable) ? OFF : ((enable && wake) ? ACTIVE : ((enable && !wake) ? SLEEP : (SLEEP)));
            default: next_state = OFF;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= OFF;
        else
            state <= next_state;
    end

    always @* begin
        active = (state == ACTIVE);
        sleeping = (state == SLEEP);
        off = (state == OFF);
    end
endmodule

module mode_controller_0002_mutant_force_exit_t2 (
    input  wire clk,
    input  wire rst,
    input  wire enable,
    input  wire sleep,
    input  wire wake,
    output reg  active,
    output reg  sleeping,
    output reg  off
);
    localparam [1:0] OFF   = 2'd0;
    localparam [1:0] ACTIVE = 2'd1;
    localparam [1:0] SLEEP = 2'd2;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            OFF: next_state = ACTIVE;
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
        active = 1'b0;
        sleeping = 1'b0;
        off = 1'b0;
        case (state)
            OFF: begin
                active = 1'b0;
                sleeping = 1'b0;
                off = 1'b1;
            end
            ACTIVE: begin
                active = 1'b1;
                sleeping = 1'b0;
                off = 1'b0;
            end
            SLEEP: begin
                active = 1'b0;
                sleeping = 1'b1;
                off = 1'b0;
            end
            default: begin end
        endcase
    end
endmodule

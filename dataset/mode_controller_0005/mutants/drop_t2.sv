module mode_controller_0005_mutant_drop_t2 (
    input  wire clk,
    input  wire rst,
    input  wire activate,
    input  wire boost,
    input  wire idle,
    output reg  active,
    output reg  boosted,
    output reg  idle_mode
);
    localparam [1:0] IDLE  = 2'd0;
    localparam [1:0] ACTIVE = 2'd1;
    localparam [1:0] BOOST = 2'd2;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            IDLE: next_state = (activate) ? ACTIVE : (IDLE);
            ACTIVE: next_state = (boost) ? BOOST : ((!boost && idle) ? IDLE : ((!boost && !idle) ? ACTIVE : (ACTIVE)));
            BOOST: next_state = (boost) ? BOOST : ((!boost) ? ACTIVE : (BOOST));
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
        active = 1'b0;
        boosted = 1'b0;
        idle_mode = 1'b0;
        case (state)
            IDLE: begin
                active = 1'b0;
                boosted = 1'b0;
                idle_mode = 1'b1;
            end
            ACTIVE: begin
                active = 1'b1;
                boosted = 1'b0;
                idle_mode = 1'b0;
            end
            BOOST: begin
                active = 1'b0;
                boosted = 1'b1;
                idle_mode = 1'b0;
            end
            default: begin end
        endcase
    end
endmodule

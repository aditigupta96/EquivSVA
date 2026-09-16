module mode_controller_0005_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire activate,
    input  wire boost,
    input  wire idle,
    output reg  active,
    output reg  boosted,
    output reg  idle_mode
);
    localparam [2:0] IDLE  = 3'b001;
    localparam [2:0] ACTIVE = 3'b010;
    localparam [2:0] BOOST = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (activate) ? ACTIVE : ((!activate) ? IDLE : (IDLE));
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
        active = (state == ACTIVE);
        boosted = (state == BOOST);
        idle_mode = (state == IDLE);
    end
endmodule

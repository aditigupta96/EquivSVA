module mode_controller_0006_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire unlock,
    input  wire lock,
    input  wire operate,
    output reg  locked,
    output reg  ready,
    output reg  active
);
    localparam [2:0] LOCKED = 3'b001;
    localparam [2:0] READY = 3'b010;
    localparam [2:0] ACTIVE = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = LOCKED;
        case (state)
            LOCKED: next_state = (unlock) ? READY : ((!unlock) ? LOCKED : (LOCKED));
            READY: next_state = (lock) ? LOCKED : ((!lock && operate) ? ACTIVE : ((!lock && !operate) ? READY : (READY)));
            ACTIVE: next_state = (lock) ? LOCKED : ((!lock && !operate) ? READY : ((!lock && operate) ? ACTIVE : (ACTIVE)));
            default: next_state = LOCKED;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= LOCKED;
        else
            state <= next_state;
    end

    always @* begin
        locked = (state == LOCKED);
        ready = (state == READY);
        active = (state == ACTIVE);
    end
endmodule

module mode_controller_0006_mutant_drop_t2 (
    input  wire clk,
    input  wire rst,
    input  wire unlock,
    input  wire lock,
    input  wire operate,
    output reg  locked,
    output reg  ready,
    output reg  active
);
    localparam [1:0] LOCKED = 2'd0;
    localparam [1:0] READY = 2'd1;
    localparam [1:0] ACTIVE = 2'd2;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            LOCKED: next_state = (unlock) ? READY : (LOCKED);
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
        locked = 1'b0;
        ready = 1'b0;
        active = 1'b0;
        case (state)
            LOCKED: begin
                locked = 1'b1;
                ready = 1'b0;
                active = 1'b0;
            end
            READY: begin
                locked = 1'b0;
                ready = 1'b1;
                active = 1'b0;
            end
            ACTIVE: begin
                locked = 1'b0;
                ready = 1'b0;
                active = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

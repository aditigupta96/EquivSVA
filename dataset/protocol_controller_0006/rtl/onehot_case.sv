module protocol_controller_0006_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire acquire,
    input  wire release,
    output reg  waiting,
    output reg  held
);
    localparam [2:0] IDLE  = 3'b001;
    localparam [2:0] WAIT  = 3'b010;
    localparam [2:0] HELD  = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (acquire) ? WAIT : ((!acquire) ? IDLE : (IDLE));
            WAIT: next_state = (acquire) ? HELD : ((!acquire) ? WAIT : (WAIT));
            HELD: next_state = (release) ? IDLE : ((!release) ? HELD : (HELD));
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
        waiting = (state == WAIT);
        held = (state == HELD);
    end
endmodule

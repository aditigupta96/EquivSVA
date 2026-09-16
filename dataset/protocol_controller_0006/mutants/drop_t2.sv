module protocol_controller_0006_mutant_drop_t2 (
    input  wire clk,
    input  wire rst,
    input  wire acquire,
    input  wire release,
    output reg  waiting,
    output reg  held
);
    localparam [1:0] IDLE  = 2'd0;
    localparam [1:0] WAIT  = 2'd1;
    localparam [1:0] HELD  = 2'd2;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            IDLE: next_state = (acquire) ? WAIT : (IDLE);
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
        waiting = 1'b0;
        held = 1'b0;
        case (state)
            IDLE: begin
                waiting = 1'b0;
                held = 1'b0;
            end
            WAIT: begin
                waiting = 1'b1;
                held = 1'b0;
            end
            HELD: begin
                waiting = 1'b0;
                held = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

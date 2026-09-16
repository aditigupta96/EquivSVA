module handshake_0007_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire produce,
    input  wire ready,
    output reg  valid,
    output reg  done
);
    localparam [1:0] F_IDLE         = 2'd0;
    localparam [1:0] F_VALID        = 2'd1;
    localparam [1:0] F_DONE         = 2'd2;

    reg [1:0] state, next_state;

    wire guard_idle_0 = (produce);
    wire guard_idle_1 = (!produce);
    wire guard_valid_0 = (ready);
    wire guard_valid_1 = (!ready);

    always @* begin
        next_state = state;
        case (state)
            F_IDLE: begin
                if (guard_idle_0)
                    next_state = F_VALID;
                else if (guard_idle_1)
                    next_state = F_IDLE;
            end
            F_VALID: begin
                if (guard_valid_0)
                    next_state = F_DONE;
                else if (guard_valid_1)
                    next_state = F_VALID;
            end
            F_DONE: begin
                next_state = F_IDLE;
            end
            default: next_state = F_IDLE;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= F_IDLE;
        else
            state <= next_state;
    end

    always @* begin
        valid = 1'b0;
        done = 1'b0;
        case (state)
            F_IDLE: begin
                valid = 1'b0;
                done = 1'b0;
            end
            F_VALID: begin
                valid = 1'b1;
                done = 1'b0;
            end
            F_DONE: begin
                valid = 1'b0;
                done = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

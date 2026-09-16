module timer_0006_mutant_warning_skipped (
    input  wire clk,
    input  wire rst,
    input  wire tick,
    input  wire kick,
    output reg  armed,
    output reg  warning,
    output reg  timeout
);
    localparam [1:0] ARMED = 2'd0;
    localparam [1:0] WARN  = 2'd1;
    localparam [1:0] TIMEOUT = 2'd2;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            ARMED: next_state = TIMEOUT;
            WARN: next_state = (kick) ? ARMED : ((!kick && tick) ? TIMEOUT : ((!kick && !tick) ? WARN : (WARN)));
            TIMEOUT: next_state = (kick) ? ARMED : ((!kick) ? TIMEOUT : (TIMEOUT));
            default: next_state = ARMED;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= ARMED;
        else
            state <= next_state;
    end

    always @* begin
        armed = 1'b0;
        warning = 1'b0;
        timeout = 1'b0;
        case (state)
            ARMED: begin
                armed = 1'b1;
                warning = 1'b0;
                timeout = 1'b0;
            end
            WARN: begin
                armed = 1'b0;
                warning = 1'b1;
                timeout = 1'b0;
            end
            TIMEOUT: begin
                armed = 1'b0;
                warning = 1'b0;
                timeout = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

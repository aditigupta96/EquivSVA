module timer_0006_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire tick,
    input  wire kick,
    output reg  armed,
    output reg  warning,
    output reg  timeout
);
    localparam [2:0] ARMED = 3'b001;
    localparam [2:0] WARN  = 3'b010;
    localparam [2:0] TIMEOUT = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = ARMED;
        case (state)
            ARMED: next_state = (kick) ? ARMED : ((!kick && tick) ? WARN : ((!kick && !tick) ? ARMED : (ARMED)));
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
        armed = (state == ARMED);
        warning = (state == WARN);
        timeout = (state == TIMEOUT);
    end
endmodule

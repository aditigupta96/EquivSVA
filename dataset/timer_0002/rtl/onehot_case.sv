module timer_0002_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire service,
    output reg  active,
    output reg  window_open,
    output reg  serviced,
    output reg  early_fault,
    output reg  timeout
);
    localparam [5:0] IDLE  = 6'b000001;
    localparam [5:0] EARLY = 6'b000010;
    localparam [5:0] WINDOW = 6'b000100;
    localparam [5:0] SERVICED = 6'b001000;
    localparam [5:0] EARLY_FAULT = 6'b010000;
    localparam [5:0] TIMEOUT = 6'b100000;

    reg [5:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (start) ? EARLY : (IDLE);
            EARLY: next_state = (service) ? EARLY_FAULT : (WINDOW);
            WINDOW: next_state = (service) ? SERVICED : (TIMEOUT);
            SERVICED: next_state = IDLE;
            EARLY_FAULT: next_state = IDLE;
            TIMEOUT: next_state = IDLE;
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
        active = (state == EARLY) || (state == WINDOW);
        window_open = (state == WINDOW);
        serviced = (state == SERVICED);
        early_fault = (state == EARLY_FAULT);
        timeout = (state == TIMEOUT);
    end
endmodule

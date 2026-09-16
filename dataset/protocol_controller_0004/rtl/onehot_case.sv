module protocol_controller_0004_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire success,
    input  wire retry,
    input  wire reset_fail,
    output reg  attempting,
    output reg  retrying,
    output reg  done,
    output reg  failed
);
    localparam [5:0] IDLE  = 6'b000001;
    localparam [5:0] ATTEMPT1 = 6'b000010;
    localparam [5:0] RETRY = 6'b000100;
    localparam [5:0] ATTEMPT2 = 6'b001000;
    localparam [5:0] DONE  = 6'b010000;
    localparam [5:0] FAILED = 6'b100000;

    reg [5:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (start) ? ATTEMPT1 : ((!start) ? IDLE : (IDLE));
            ATTEMPT1: next_state = (success) ? DONE : ((!success && retry) ? RETRY : ((!success && !retry) ? FAILED : (ATTEMPT1)));
            RETRY: next_state = ATTEMPT2;
            ATTEMPT2: next_state = (success) ? DONE : ((!success) ? FAILED : (ATTEMPT2));
            DONE: next_state = IDLE;
            FAILED: next_state = (reset_fail) ? IDLE : ((!reset_fail) ? FAILED : (FAILED));
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
        attempting = (state == ATTEMPT1) || (state == ATTEMPT2);
        retrying = (state == RETRY);
        done = (state == DONE);
        failed = (state == FAILED);
    end
endmodule

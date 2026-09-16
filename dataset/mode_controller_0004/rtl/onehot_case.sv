module mode_controller_0004_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire fault,
    input  wire clear,
    output reg  running,
    output reg  safe,
    output reg  faulted
);
    localparam [2:0] SAFE  = 3'b001;
    localparam [2:0] RUN   = 3'b010;
    localparam [2:0] FAULT = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = SAFE;
        case (state)
            SAFE: next_state = (start) ? RUN : ((!start) ? SAFE : (SAFE));
            RUN: next_state = (fault) ? FAULT : ((!fault) ? RUN : (RUN));
            FAULT: next_state = (clear) ? SAFE : ((!clear) ? FAULT : (FAULT));
            default: next_state = SAFE;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= SAFE;
        else
            state <= next_state;
    end

    always @* begin
        running = (state == RUN);
        safe = (state == SAFE);
        faulted = (state == FAULT);
    end
endmodule

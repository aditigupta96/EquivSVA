module mode_controller_0007_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire run,
    input  wire fault,
    input  wire clear,
    output reg  standby,
    output reg  running,
    output reg  faulted
);
    localparam [2:0] STANDBY = 3'b001;
    localparam [2:0] RUN   = 3'b010;
    localparam [2:0] FAULT = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = STANDBY;
        case (state)
            STANDBY: next_state = (run) ? RUN : ((!run) ? STANDBY : (STANDBY));
            RUN: next_state = (fault) ? FAULT : ((!fault && run) ? RUN : ((!fault && !run) ? STANDBY : (RUN)));
            FAULT: next_state = (clear) ? STANDBY : ((!clear) ? FAULT : (FAULT));
            default: next_state = STANDBY;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= STANDBY;
        else
            state <= next_state;
    end

    always @* begin
        standby = (state == STANDBY);
        running = (state == RUN);
        faulted = (state == FAULT);
    end
endmodule

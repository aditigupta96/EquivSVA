module mode_controller_0001_mutant_wake_ignored (
    input  wire clk,
    input  wire rst,
    input  wire enable,
    input  wire wake,
    input  wire fault,
    input  wire clear_fault,
    output reg  standby,
    output reg  active,
    output reg  faulted
);
    localparam [1:0] OFF   = 2'd0;
    localparam [1:0] STANDBY = 2'd1;
    localparam [1:0] ACTIVE = 2'd2;
    localparam [1:0] FAULT = 2'd3;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            OFF: next_state = (enable) ? STANDBY : ((!enable) ? OFF : (OFF));
            STANDBY: next_state = (fault) ? FAULT : ((!fault && !enable) ? OFF : ((!fault && enable && !wake) ? STANDBY : (STANDBY)));
            ACTIVE: next_state = (fault) ? FAULT : ((!fault && !enable) ? OFF : ((!fault && enable && !wake) ? STANDBY : ((!fault && enable && wake) ? ACTIVE : (ACTIVE))));
            FAULT: next_state = (clear_fault) ? OFF : ((!clear_fault) ? FAULT : (FAULT));
            default: next_state = OFF;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= OFF;
        else
            state <= next_state;
    end

    always @* begin
        standby = 1'b0;
        active = 1'b0;
        faulted = 1'b0;
        case (state)
            OFF: begin
                standby = 1'b0;
                active = 1'b0;
                faulted = 1'b0;
            end
            STANDBY: begin
                standby = 1'b1;
                active = 1'b0;
                faulted = 1'b0;
            end
            ACTIVE: begin
                standby = 1'b0;
                active = 1'b1;
                faulted = 1'b0;
            end
            FAULT: begin
                standby = 1'b0;
                active = 1'b0;
                faulted = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

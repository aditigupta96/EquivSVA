module mode_controller_0001_onehot_case (
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
    localparam [3:0] OFF   = 4'b0001;
    localparam [3:0] STANDBY = 4'b0010;
    localparam [3:0] ACTIVE = 4'b0100;
    localparam [3:0] FAULT = 4'b1000;

    reg [3:0] state, next_state;

    always @* begin
        next_state = OFF;
        case (state)
            OFF: next_state = (enable) ? STANDBY : ((!enable) ? OFF : (OFF));
            STANDBY: next_state = (fault) ? FAULT : ((!fault && !enable) ? OFF : ((!fault && enable && wake) ? ACTIVE : ((!fault && enable && !wake) ? STANDBY : (STANDBY))));
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
        standby = (state == STANDBY);
        active = (state == ACTIVE);
        faulted = (state == FAULT);
    end
endmodule

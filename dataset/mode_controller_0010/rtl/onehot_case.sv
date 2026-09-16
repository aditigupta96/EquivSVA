module mode_controller_0010_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire enable,
    input  wire auto_mode,
    input  wire turn_off,
    output reg  manual,
    output reg  auto_active,
    output reg  off
);
    localparam [2:0] OFF   = 3'b001;
    localparam [2:0] MANUAL = 3'b010;
    localparam [2:0] AUTO  = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = OFF;
        case (state)
            OFF: next_state = (enable && auto_mode) ? AUTO : ((enable && !auto_mode) ? MANUAL : ((!enable) ? OFF : (OFF)));
            MANUAL: next_state = (turn_off) ? OFF : ((!turn_off && auto_mode) ? AUTO : ((!turn_off && !auto_mode) ? MANUAL : (MANUAL)));
            AUTO: next_state = (turn_off) ? OFF : ((!turn_off && !auto_mode) ? MANUAL : ((!turn_off && auto_mode) ? AUTO : (AUTO)));
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
        manual = (state == MANUAL);
        auto_active = (state == AUTO);
        off = (state == OFF);
    end
endmodule

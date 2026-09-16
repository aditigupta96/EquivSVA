module mode_controller_0003_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire enable,
    input  wire maintenance,
    input  wire exit_maintenance,
    output reg  normal,
    output reg  maint,
    output reg  off
);
    localparam [2:0] OFF   = 3'b001;
    localparam [2:0] NORMAL = 3'b010;
    localparam [2:0] MAINT = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = OFF;
        case (state)
            OFF: next_state = (enable) ? NORMAL : ((!enable) ? OFF : (OFF));
            NORMAL: next_state = (maintenance) ? MAINT : ((!maintenance && !enable) ? OFF : ((!maintenance && enable) ? NORMAL : (NORMAL)));
            MAINT: next_state = (exit_maintenance) ? NORMAL : ((!exit_maintenance) ? MAINT : (MAINT));
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
        normal = (state == NORMAL);
        maint = (state == MAINT);
        off = (state == OFF);
    end
endmodule

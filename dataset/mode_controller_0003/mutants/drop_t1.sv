module mode_controller_0003_mutant_drop_t1 (
    input  wire clk,
    input  wire rst,
    input  wire enable,
    input  wire maintenance,
    input  wire exit_maintenance,
    output reg  normal,
    output reg  maint,
    output reg  off
);
    localparam [1:0] OFF   = 2'd0;
    localparam [1:0] NORMAL = 2'd1;
    localparam [1:0] MAINT = 2'd2;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            OFF: next_state = (!enable) ? OFF : (OFF);
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
        normal = 1'b0;
        maint = 1'b0;
        off = 1'b0;
        case (state)
            OFF: begin
                normal = 1'b0;
                maint = 1'b0;
                off = 1'b1;
            end
            NORMAL: begin
                normal = 1'b1;
                maint = 1'b0;
                off = 1'b0;
            end
            MAINT: begin
                normal = 1'b0;
                maint = 1'b1;
                off = 1'b0;
            end
            default: begin end
        endcase
    end
endmodule

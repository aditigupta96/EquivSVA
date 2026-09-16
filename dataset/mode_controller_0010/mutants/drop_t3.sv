module mode_controller_0010_mutant_drop_t3 (
    input  wire clk,
    input  wire rst,
    input  wire enable,
    input  wire auto_mode,
    input  wire disable,
    output reg  manual,
    output reg  automatic,
    output reg  off
);
    localparam [1:0] OFF   = 2'd0;
    localparam [1:0] MANUAL = 2'd1;
    localparam [1:0] AUTO  = 2'd2;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            OFF: next_state = (enable && auto_mode) ? AUTO : ((enable && !auto_mode) ? MANUAL : (OFF));
            MANUAL: next_state = (disable) ? OFF : ((!disable && auto_mode) ? AUTO : ((!disable && !auto_mode) ? MANUAL : (MANUAL)));
            AUTO: next_state = (disable) ? OFF : ((!disable && !auto_mode) ? MANUAL : ((!disable && auto_mode) ? AUTO : (AUTO)));
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
        manual = 1'b0;
        automatic = 1'b0;
        off = 1'b0;
        case (state)
            OFF: begin
                manual = 1'b0;
                automatic = 1'b0;
                off = 1'b1;
            end
            MANUAL: begin
                manual = 1'b1;
                automatic = 1'b0;
                off = 1'b0;
            end
            AUTO: begin
                manual = 1'b0;
                automatic = 1'b1;
                off = 1'b0;
            end
            default: begin end
        endcase
    end
endmodule

module mode_controller_0009_canonical_case (
    input  wire clk,
    input  wire rst,
    input  wire enable,
    input  wire fail,
    input  wire recover,
    output reg  primary,
    output reg  backup,
    output reg  off
);
    localparam [1:0] OFF   = 2'd0;
    localparam [1:0] PRIMARY = 2'd1;
    localparam [1:0] BACKUP = 2'd2;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            OFF: next_state = (enable) ? PRIMARY : ((!enable) ? OFF : (OFF));
            PRIMARY: next_state = (fail) ? BACKUP : ((!fail && enable) ? PRIMARY : ((!fail && !enable) ? OFF : (PRIMARY)));
            BACKUP: next_state = (recover) ? PRIMARY : ((!recover && enable) ? BACKUP : ((!recover && !enable) ? OFF : (BACKUP)));
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
        primary = 1'b0;
        backup = 1'b0;
        off = 1'b0;
        case (state)
            OFF: begin
                primary = 1'b0;
                backup = 1'b0;
                off = 1'b1;
            end
            PRIMARY: begin
                primary = 1'b1;
                backup = 1'b0;
                off = 1'b0;
            end
            BACKUP: begin
                primary = 1'b0;
                backup = 1'b1;
                off = 1'b0;
            end
            default: begin end
        endcase
    end
endmodule

module mode_controller_0009_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire enable,
    input  wire fail,
    input  wire recover,
    output reg  primary,
    output reg  backup,
    output reg  off
);
    localparam [2:0] OFF   = 3'b001;
    localparam [2:0] PRIMARY = 3'b010;
    localparam [2:0] BACKUP = 3'b100;

    reg [2:0] state, next_state;

    always @* begin
        next_state = OFF;
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
        primary = (state == PRIMARY);
        backup = (state == BACKUP);
        off = (state == OFF);
    end
endmodule

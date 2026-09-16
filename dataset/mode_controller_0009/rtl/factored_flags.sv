module mode_controller_0009_factored_flags (
    input  wire clk,
    input  wire rst,
    input  wire enable,
    input  wire fail,
    input  wire recover,
    output reg  primary,
    output reg  backup,
    output reg  off
);
    localparam [1:0] F_OFF          = 2'd0;
    localparam [1:0] F_PRIMARY      = 2'd1;
    localparam [1:0] F_BACKUP       = 2'd2;

    reg [1:0] state, next_state;

    wire guard_off_0 = (enable);
    wire guard_off_1 = (!enable);
    wire guard_primary_0 = (fail);
    wire guard_primary_1 = (!fail && enable);
    wire guard_primary_2 = (!fail && !enable);
    wire guard_backup_0 = (recover);
    wire guard_backup_1 = (!recover && enable);
    wire guard_backup_2 = (!recover && !enable);

    always @* begin
        next_state = state;
        case (state)
            F_OFF: begin
                if (guard_off_0)
                    next_state = F_PRIMARY;
                else if (guard_off_1)
                    next_state = F_OFF;
            end
            F_PRIMARY: begin
                if (guard_primary_0)
                    next_state = F_BACKUP;
                else if (guard_primary_1)
                    next_state = F_PRIMARY;
                else if (guard_primary_2)
                    next_state = F_OFF;
            end
            F_BACKUP: begin
                if (guard_backup_0)
                    next_state = F_PRIMARY;
                else if (guard_backup_1)
                    next_state = F_BACKUP;
                else if (guard_backup_2)
                    next_state = F_OFF;
            end
            default: next_state = F_OFF;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= F_OFF;
        else
            state <= next_state;
    end

    always @* begin
        primary = 1'b0;
        backup = 1'b0;
        off = 1'b0;
        case (state)
            F_OFF: begin
                primary = 1'b0;
                backup = 1'b0;
                off = 1'b1;
            end
            F_PRIMARY: begin
                primary = 1'b1;
                backup = 1'b0;
                off = 1'b0;
            end
            F_BACKUP: begin
                primary = 1'b0;
                backup = 1'b1;
                off = 1'b0;
            end
            default: begin end
        endcase
    end
endmodule

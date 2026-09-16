module rate_limiter_0002_ternary_next (
    input  wire clk,
    input  wire rst,
    input  wire request,
    input  wire new_window,
    output wire [1:0] used,
    output wire epoch,
    output wire allow,
    output wire exhausted
);

    reg [1:0] used_reg;
    reg epoch_reg;

    wire [1:0] next_used_reg;
    wire next_epoch_reg;

    assign next_used_reg = (new_window) ? (2'd0) : ((!new_window && request && (used_reg < 2'd3)) ? (used_reg + 2'd1) : (used_reg));
    assign next_epoch_reg = (new_window) ? (!epoch_reg) : (epoch_reg);

    always @(posedge clk) begin
        if (rst) begin
            used_reg <= 2'd0;
            epoch_reg <= 1'b0;
        end
        else begin
            used_reg <= next_used_reg;
            epoch_reg <= next_epoch_reg;
        end
    end

    assign used = used_reg;
    assign epoch = epoch_reg;
    assign allow = used_reg < 2'd3;
    assign exhausted = used_reg == 2'd3;
endmodule

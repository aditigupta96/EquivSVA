module timer_0007_mutant_count_without_tick (
    input  wire clk,
    input  wire rst,
    input  wire load,
    input  wire tick,
    output reg  [2:0] remaining,
    output wire expired
);

    always @(posedge clk) begin
        if (rst) begin
            remaining <= 3'd0;
        end
        else begin
            if (load) remaining <= 3'd7;
            else if (!load && (remaining > 3'd0)) remaining <= remaining - 3'd1;
            else remaining <= remaining;
        end
    end

    assign expired = remaining == 3'd0;
endmodule

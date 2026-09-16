module arbiter_0008_mutant_drop_t1 (
    input  wire clk,
    input  wire rst,
    input  wire req0,
    input  wire req1,
    input  wire req2,
    output reg  grant0,
    output reg  grant1,
    output reg  grant2
);
    localparam [1:0] IDLE  = 2'd0;
    localparam [1:0] G0    = 2'd1;
    localparam [1:0] G1    = 2'd2;
    localparam [1:0] G2    = 2'd3;

    reg [1:0] state, next_state;

    always @* begin
        next_state = state;
        case (state)
            IDLE: next_state = (!req0 && req1) ? G1 : ((!req0 && !req1 && req2) ? G2 : ((!req0 && !req1 && !req2) ? IDLE : (IDLE)));
            G0: next_state = IDLE;
            G1: next_state = IDLE;
            G2: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @* begin
        grant0 = 1'b0;
        grant1 = 1'b0;
        grant2 = 1'b0;
        case (state)
            IDLE: begin
                grant0 = 1'b0;
                grant1 = 1'b0;
                grant2 = 1'b0;
            end
            G0: begin
                grant0 = 1'b1;
                grant1 = 1'b0;
                grant2 = 1'b0;
            end
            G1: begin
                grant0 = 1'b0;
                grant1 = 1'b1;
                grant2 = 1'b0;
            end
            G2: begin
                grant0 = 1'b0;
                grant1 = 1'b0;
                grant2 = 1'b1;
            end
            default: begin end
        endcase
    end
endmodule

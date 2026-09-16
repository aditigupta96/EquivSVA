module protocol_controller_0005_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire prepare_ok,
    input  wire commit_ok,
    output reg  preparing,
    output reg  committing,
    output reg  done
);
    localparam [3:0] IDLE  = 4'b0001;
    localparam [3:0] PREP  = 4'b0010;
    localparam [3:0] COMMIT = 4'b0100;
    localparam [3:0] DONE  = 4'b1000;

    reg [3:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (start) ? PREP : ((!start) ? IDLE : (IDLE));
            PREP: next_state = (prepare_ok) ? COMMIT : ((!prepare_ok) ? PREP : (PREP));
            COMMIT: next_state = (commit_ok) ? DONE : ((!commit_ok) ? COMMIT : (COMMIT));
            DONE: next_state = IDLE;
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
        preparing = (state == PREP);
        committing = (state == COMMIT);
        done = (state == DONE);
    end
endmodule

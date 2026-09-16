module protocol_controller_0003_onehot_case (
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire prepared,
    input  wire commit,
    input  wire abort,
    input  wire recover,
    output reg  preparing,
    output reg  ready_commit,
    output reg  committed,
    output reg  aborted
);
    localparam [4:0] IDLE  = 5'b00001;
    localparam [4:0] PREPARE = 5'b00010;
    localparam [4:0] READY = 5'b00100;
    localparam [4:0] COMMITTED = 5'b01000;
    localparam [4:0] ABORTED = 5'b10000;

    reg [4:0] state, next_state;

    always @* begin
        next_state = IDLE;
        case (state)
            IDLE: next_state = (start) ? PREPARE : ((!start) ? IDLE : (IDLE));
            PREPARE: next_state = (abort) ? ABORTED : ((!abort && prepared) ? READY : ((!abort && !prepared) ? PREPARE : (PREPARE)));
            READY: next_state = (abort) ? ABORTED : ((!abort && commit) ? COMMITTED : ((!abort && !commit) ? READY : (READY)));
            COMMITTED: next_state = IDLE;
            ABORTED: next_state = (recover) ? IDLE : ((!recover) ? ABORTED : (ABORTED));
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
        preparing = (state == PREPARE);
        ready_commit = (state == READY);
        committed = (state == COMMITTED);
        aborted = (state == ABORTED);
    end
endmodule

module axis_fifo #(
    parameter integer DATA_WIDTH = 32,
    parameter integer KEEP_WIDTH = DATA_WIDTH / 8,
    parameter integer USER_WIDTH = 1,
    parameter integer DEPTH = 16
) (
    input  wire                        aclk,
    input  wire                        aresetn,

    // AXIS slave input
    input  wire [DATA_WIDTH-1:0]       s_axis_tdata,
    input  wire [KEEP_WIDTH-1:0]       s_axis_tkeep,
    input  wire                        s_axis_tvalid,
    output wire                        s_axis_tready,
    input  wire                        s_axis_tlast,
    input  wire [USER_WIDTH-1:0]       s_axis_tuser,

    // AXIS master output
    output wire [DATA_WIDTH-1:0]       m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]       m_axis_tkeep,
    output wire                        m_axis_tvalid,
    input  wire                        m_axis_tready,
    output wire                        m_axis_tlast,
    output wire [USER_WIDTH-1:0]       m_axis_tuser,

    output wire [$clog2(DEPTH+1)-1:0]  fifo_level
);

    localparam integer ADDR_WIDTH = $clog2(DEPTH);

    reg [DATA_WIDTH-1:0] data_mem [0:DEPTH-1];
    reg [KEEP_WIDTH-1:0] keep_mem [0:DEPTH-1];
    reg                  last_mem [0:DEPTH-1];
    reg [USER_WIDTH-1:0] user_mem [0:DEPTH-1];

    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;
    reg [$clog2(DEPTH+1)-1:0] count;

    wire fifo_full;
    wire fifo_empty;
    wire push;
    wire pop;

    assign fifo_full  = (count == DEPTH);
    assign fifo_empty = (count == 0);

    assign s_axis_tready = ~fifo_full;
    assign m_axis_tvalid = ~fifo_empty;

    assign m_axis_tdata = data_mem[rd_ptr];
    assign m_axis_tkeep = keep_mem[rd_ptr];
    assign m_axis_tlast = last_mem[rd_ptr];
    assign m_axis_tuser = user_mem[rd_ptr];

    assign push = s_axis_tvalid & s_axis_tready;
    assign pop  = m_axis_tvalid & m_axis_tready;

    assign fifo_level = count;

    always @(posedge aclk) begin
        if (!aresetn) begin
            wr_ptr <= {ADDR_WIDTH{1'b0}};
            rd_ptr <= {ADDR_WIDTH{1'b0}};
            count  <= {($clog2(DEPTH+1)){1'b0}};
        end else begin
            if (push) begin
                data_mem[wr_ptr] <= s_axis_tdata;
                keep_mem[wr_ptr] <= s_axis_tkeep;
                last_mem[wr_ptr] <= s_axis_tlast;
                user_mem[wr_ptr] <= s_axis_tuser;
                wr_ptr <= (wr_ptr == DEPTH-1) ? {ADDR_WIDTH{1'b0}} : (wr_ptr + 1'b1);
            end

            if (pop) begin
                rd_ptr <= (rd_ptr == DEPTH-1) ? {ADDR_WIDTH{1'b0}} : (rd_ptr + 1'b1);
            end

            case ({push, pop})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end

endmodule

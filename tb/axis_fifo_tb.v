`timescale 1ns/1ps

module axis_fifo_tb;
    localparam DATA_WIDTH = 8;
    localparam KEEP_WIDTH = 1;
    localparam USER_WIDTH = 1;
    localparam DEPTH = 4;

    reg aclk = 1'b0;
    reg aresetn = 1'b0;

    reg  [DATA_WIDTH-1:0] s_axis_tdata;
    reg  [KEEP_WIDTH-1:0] s_axis_tkeep;
    reg                   s_axis_tvalid;
    wire                  s_axis_tready;
    reg                   s_axis_tlast;
    reg  [USER_WIDTH-1:0] s_axis_tuser;

    wire [DATA_WIDTH-1:0] m_axis_tdata;
    wire [KEEP_WIDTH-1:0] m_axis_tkeep;
    wire                  m_axis_tvalid;
    reg                   m_axis_tready;
    wire                  m_axis_tlast;
    wire [USER_WIDTH-1:0] m_axis_tuser;
    wire [$clog2(DEPTH+1)-1:0] fifo_level;

    axis_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .KEEP_WIDTH(KEEP_WIDTH),
        .USER_WIDTH(USER_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tkeep(s_axis_tkeep),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tuser(s_axis_tuser),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tkeep(m_axis_tkeep),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast),
        .m_axis_tuser(m_axis_tuser),
        .fifo_level(fifo_level)
    );

    always #5 aclk = ~aclk;

    task push_word(input [7:0] val, input last);
    begin
        @(posedge aclk);
        s_axis_tdata  <= val;
        s_axis_tkeep  <= 1'b1;
        s_axis_tlast  <= last;
        s_axis_tuser  <= 1'b0;
        s_axis_tvalid <= 1'b1;
        while (!s_axis_tready) @(posedge aclk);
        @(posedge aclk);
        s_axis_tvalid <= 1'b0;
    end
    endtask

    task pop_word(input [7:0] exp, input exp_last);
    begin
        m_axis_tready <= 1'b1;
        while (!m_axis_tvalid) @(posedge aclk);
        if (m_axis_tdata !== exp || m_axis_tlast !== exp_last) begin
            $display("ERROR exp=%0d/%0d got=%0d/%0d", exp, exp_last, m_axis_tdata, m_axis_tlast);
            $fatal(1);
        end
        @(posedge aclk);
        m_axis_tready <= 1'b0;
    end
    endtask

    initial begin
        s_axis_tdata  = '0;
        s_axis_tkeep  = '0;
        s_axis_tvalid = 1'b0;
        s_axis_tlast  = 1'b0;
        s_axis_tuser  = '0;
        m_axis_tready = 1'b0;

        repeat (3) @(posedge aclk);
        aresetn = 1'b1;

        push_word(8'h11, 1'b0);
        push_word(8'h22, 1'b0);
        push_word(8'h33, 1'b1);

        pop_word(8'h11, 1'b0);
        pop_word(8'h22, 1'b0);
        pop_word(8'h33, 1'b1);

        $display("PASS axis_fifo_tb");
        $finish;
    end
endmodule

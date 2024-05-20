`timescale 1ns / 1ps
module tb();

localparam T_DATA_WIDTH = 4;
localparam T_DATA_RATIO = 2;
localparam Q = 5;

reg clk, rst_n;
integer cnt;
reg[T_DATA_WIDTH-1:0] samples [4:0];

logic [T_DATA_WIDTH-1:0] s_data_i;
logic                    s_last_i;
logic                    s_valid_i;
logic                    s_ready_o;
logic [T_DATA_WIDTH-1:0] m_data_o [T_DATA_RATIO-1:0];
logic [T_DATA_RATIO-1:0] m_keep_o;
logic                    m_last_o;
logic                    m_valid_o;
logic                    m_ready_i;

stream_upsize#(T_DATA_WIDTH, T_DATA_RATIO) 
                su(.clk(clk), .rst_n(rst_n), .s_data_i(s_data_i), .s_last_i(s_last_i), .s_valid_i(s_valid_i), 
                .s_ready_o(s_ready_o), .m_data_o(m_data_o), .m_keep_o(m_keep_o), .m_last_o(m_last_o), .m_valid_o(m_valid_o), .m_ready_i(m_ready_i));

//assign s_data_i = samples[cnt];

initial begin
    m_ready_i=1;
    cnt=1;
    s_last_i=0;

    samples[0]=4'h1;
    samples[1]=4'ha;
    samples[2]=4'h3;
    samples[3]=4'h2;
    samples[4]=4'h6;
    
    s_data_i=samples[0];
    
    clk<=0;
    rst_n<=1;//power-on reset
    #100;
    rst_n<=0;
    s_valid_i=1;
end

always #5 clk <= ~clk;

always@(posedge clk) begin
    if(s_last_i)s_valid_i<=0;
    if(s_ready_o && !rst_n)begin
        cnt <= cnt+1;
        s_data_i <= samples[cnt];
        if(cnt == Q-1) s_last_i <= 1;
        if(cnt <= Q-1)s_data_i <= samples[cnt];
    end
end
endmodule

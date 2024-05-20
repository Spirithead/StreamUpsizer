`timescale 1ns / 1ps

module stream_upsize#(
    parameter T_DATA_WIDTH = 1,
              T_DATA_RATIO = 2

    )(
        input  logic                    clk,
        input  logic                    rst_n,
        input  logic [T_DATA_WIDTH-1:0] s_data_i,
        input  logic                    s_last_i,
        input  logic                    s_valid_i,
        output logic                    s_ready_o,
        output logic [T_DATA_WIDTH-1:0] m_data_o [T_DATA_RATIO-1:0],
        output logic [T_DATA_RATIO-1:0] m_keep_o,
        output logic                    m_last_o,
        output logic                    m_valid_o,
        input  logic                    m_ready_i
    );
    
    reg [T_DATA_WIDTH-1:0] fifo [T_DATA_RATIO*2-1:0];
    reg [T_DATA_RATIO*2-1:0] fifo_valid;
    reg [T_DATA_RATIO-1:0] cnt, pnt;
    reg [T_DATA_WIDTH-1:0] fixed_data [T_DATA_RATIO-1:0];
    reg [T_DATA_RATIO-1:0] fixed_valid;
    reg enter, last_enter, flush;
    
    assign m_data_o = fixed_data;
    assign m_keep_o = fixed_valid;
    
    always@(posedge rst_n, posedge clk) begin
        if(rst_n)begin
            for(int i=0;i<T_DATA_RATIO*2;i=i+1)
                fifo[i] <= 0;
            for(int i=0;i<T_DATA_RATIO;i=i+1)
                fixed_data[i] <= 0;    
            fifo_valid <= 0;
            cnt <= 0;
            pnt <= 0;
            fixed_valid <= 0;
            s_ready_o <= 1;m_valid_o<=0;
            enter<=0;last_enter<=0;m_last_o<=0;flush<=0;
        end
        
        else begin
            if(m_ready_i) begin
                if((enter || last_enter) && !flush)begin
                    for(int j=0;j<T_DATA_RATIO;j=j+1)begin
                        fixed_data[j] <= fifo[pnt+j];
                        fixed_valid[j] <= fifo_valid[pnt+j];
                        fifo_valid[j] <= 0;
                    end
                    m_valid_o <= 1;
                    flush <= 1;
                    if(pnt + T_DATA_RATIO >= T_DATA_RATIO*2) pnt <= 0;
                    else pnt <= pnt + T_DATA_RATIO;
                    enter <= 0;
                    if(last_enter) begin
                        m_last_o <= 1;
                        last_enter <= 0;
                    end
                end
                else if(flush)begin
                    for(int j=0;j<T_DATA_RATIO;j=j+1)begin
                        fixed_data[j] <= 0;
                        fixed_valid[j] <= 0;
                        m_valid_o <= 0;
                    end
                    flush <= 0;
                end  
            end
            
            
            if(m_ready_i && s_valid_i && s_ready_o)begin
                fifo[cnt] <= s_data_i;
                fifo_valid[cnt] <= 1;
                
                if(cnt == T_DATA_RATIO*2-1) cnt <= 0;
                else cnt <= cnt + 1;
                
                if(cnt == T_DATA_RATIO-1 || cnt == T_DATA_RATIO*2-1) enter <= 1;
                
                if(s_last_i)begin 
                    s_ready_o <= 0;
                    last_enter <= 1;
                end
                else begin
                    s_ready_o <= 1;
                    last_enter <= 0;
                end
            end
            else s_ready_o <= 0;
        end
    end
endmodule

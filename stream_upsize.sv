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
    
    reg [T_DATA_WIDTH-1:0] fifo [T_DATA_RATIO*2-1:0];//буфер
    reg [T_DATA_RATIO*2-1:0] fifo_valid;// флаги валидности слов в буфере
    reg [T_DATA_RATIO-1:0] cnt, pnt;//счётчик текущего ввода в буфер и счётчик текущего вывода из буфера
    reg [T_DATA_WIDTH-1:0] fixed_data [T_DATA_RATIO-1:0];//выходные регистры слов
    reg [T_DATA_RATIO-1:0] fixed_valid;//выходные регистры флагов валидности
    reg enter, last_enter, flush;//флаг вывода в выходные регистры, флаг последнего в транзакции вывода в выходные регистры,
                                 //флаг сброса выходных регистров
    
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
                        fixed_data[j] <= fifo[pnt+j];//cлова и флаги валидности фиксируются
                        fixed_valid[j] <= fifo_valid[pnt+j];
                        fifo_valid[j] <= 0;//валидность выведенных слов будет сброшена
                    end
                    m_valid_o <= 1;//на момент вывода слов выходные данные станут валидными 
                    flush <= 1;//на следующем такте выходные данные будут сброшены
                    if(pnt + T_DATA_RATIO >= T_DATA_RATIO*2) pnt <= 0;//переполнение указателя
                    else pnt <= pnt + T_DATA_RATIO;
                    enter <= 0;
                    if(last_enter) begin//после вывода последнего слова транзакции все данные сбрасываются для след. транзакции
                        m_last_o <= 1;
                        last_enter <= 0;
                        s_ready_o <= 1;//устройство готово принимать слова новой транзакции
                        cnt <= 0;
                        pnt <= 0;
                        fifo_valid <= 0;
                    end
                end
                else if(flush)begin
                    for(int j=0;j<T_DATA_RATIO;j=j+1)begin
                        fixed_data[j] <= 0;
                        fixed_valid[j] <= 0;
                    end
                    m_valid_o <= 0;
                    flush <= 0;
                    m_last_o <= 0;
                end  
            end
            
            
            if(m_ready_i && s_valid_i && s_ready_o)begin
                fifo[cnt] <= s_data_i;
                fifo_valid[cnt] <= 1;//новое слово помечается как валидное
                
                if(cnt == T_DATA_RATIO*2-1) cnt <= 0;//переполнение указателя
                else cnt <= cnt + 1;
                
                if(cnt == T_DATA_RATIO-1 || cnt == T_DATA_RATIO*2-1) enter <= 1;
                
                if(s_last_i)begin 
                    s_ready_o <= 0;//если слово последнее, устройство перестаёт быть готовым принимать новые слова
                    last_enter <= 1;
                end
                else begin
                    s_ready_o <= 1;
                    last_enter <= 0;
                end
            end
            else if(!m_ready_i && !s_valid_i) s_ready_o <= 0;
        end
    end
endmodule

`timescale 1ns / 1ps


module uart_tx (
    input clk,
    input rst,
    input baud_tick,
    input start,
    input [7:0] din,
    output o_tx_busy,
    output o_tx_done,
    output o_tx
);

    //fsm
    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;
    reg [1:0] c_state, n_state;
    reg tx_reg, tx_next;
    reg [2:0]
        data_cnt_reg,
        data_cnt_next;  //데이터 비트 전송 반복구조를 위해
    reg [3:0]
        b_cnt_reg,
        b_cnt_next; //설정된 baudrate의 8배된 것을 8배 필터링 (8개틱당 1개)
    reg r_busy_reg, r_busy_next, r_done_reg, r_done_next;

    assign o_tx_done = r_done_reg;
    assign o_tx_busy = r_busy_reg;

    assign o_tx = tx_reg;

    //state register
    always @(posedge clk, posedge rst) begin
        if (rst) begin  //초기상태
            c_state <= 0;
            tx_reg <= 1'b1;  //초기 출력 high
            data_cnt_reg <= 0;
            b_cnt_reg <= 0;
            r_busy_reg <= 0;
            r_done_reg <= 0;
        end else begin
            c_state <= n_state;
            tx_reg <= tx_next;
            data_cnt_reg <= data_cnt_next;
            b_cnt_reg <= b_cnt_next;
            r_busy_reg <= r_busy_next;
            r_done_reg <= r_done_next;
        end
    end



    //next state CL
    always @(*) begin
        n_state = c_state;
        tx_next = tx_reg;
        data_cnt_next = data_cnt_reg;
        b_cnt_next = b_cnt_reg;
        r_busy_next = r_busy_reg;
        r_done_next = r_done_reg;

        case (c_state)
            IDLE: begin
                b_cnt_next = 0;
                data_cnt_next = 0;
                tx_next = 1;
                r_done_next = 0;
                r_busy_next = 0;
                if (start == 1'b1) begin
                    n_state = START;
                    r_busy_next = 1;
                end
            end

            START: begin
                if (baud_tick == 1'b1) begin
                    tx_next = 1'b0;
                    if (b_cnt_reg == 7) begin
                        n_state = DATA;
                        data_cnt_next = 0;
                        b_cnt_next = 0;
                    end else b_cnt_next = b_cnt_reg + 1;
                end
            end

            DATA: begin
                tx_next = din[data_cnt_reg];
                if (baud_tick == 1'b1) begin
                    if (b_cnt_reg == 7) begin
                        if (data_cnt_reg == 3'b111) begin
                            n_state = STOP;
                        end
                        b_cnt_next = 0;
                        data_cnt_next = data_cnt_reg + 1;
                    end else begin
                        b_cnt_next = b_cnt_reg + 1;
                    end
                end
            end

            STOP: begin
                tx_next = 1'b1;
                if (baud_tick == 1'b1) begin
                    if (b_cnt_reg == 3'b111) begin
                        n_state = IDLE;
                        r_done_next = 1;
                        r_busy_next = 0;
                    end
                    b_cnt_next = b_cnt_reg + 1;
                end
            end
        endcase

    end
endmodule

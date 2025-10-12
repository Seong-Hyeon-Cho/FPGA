`timescale 1ns / 1ps

module dht11_controller (
    input        clk,
    input        rst,
    input        start,
    output       dht11_done,
    output       dht11_valid,  //checksum
    output [7:0] rhdata,       //습도
    output [7:0] t_data,       //온도
    output [3:0] led,
    inout        dht11_io
);

    wire w_tick;

    tick_gen_10us U_Tick (
        .clk(clk),
        .rst(rst),
        .o_tick(w_tick)
    );

    parameter IDLE = 0, START = 1, WAIT = 2, SYNC_DOWN = 3, SYNC_UP = 4, DATA_SYNC = 5, DATA_DETECT = 6, DATA_DECISION =7 ,STOP = 8,ERROR = 9;

    reg [3:0] c_state, n_state;
    reg [$clog2(1900)-1:0] t_count_reg, t_count_next;
    reg [$clog2(40)-1:0] data_count, data_count_next;
    reg dht11_reg, dht11_next;
    reg io_en_reg, io_en_next;
    reg [39:0] data_reg, data_next;
    reg [7:0] valid_reg, valid_next;
    reg checksum_reg, checksum_next;
    reg done_reg, done_next;

    // assign dht11_valid = valid_reg;
    assign led = c_state;
    assign dht11_io = (io_en_reg) ? dht11_reg : 1'bz;
    assign rhdata = data_reg[39:32];
    assign t_data = data_reg[23:16];
    assign dht11_valid = checksum_reg;
    assign dht11_done = done_reg;

    //edge detection
    //edge1,edge2
    //edge1 <= echo
    //edge2 <= edge1
    //rising = edge1&~edge2
    //falling = ~edge1&edge2

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state      <= 0;
            t_count_reg  <= 0;
            dht11_reg    <= 1;
            io_en_reg    <= 1;
            valid_reg    <= 0;
            data_reg     <= 0;
            data_count   <= 0;
            done_reg     <= 0;
            checksum_reg <= 0;
        end else begin
            c_state      <= n_state;
            t_count_reg  <= t_count_next;
            dht11_reg    <= dht11_next;
            io_en_reg    <= io_en_next;
            valid_reg    <= valid_next;
            data_reg     <= data_next;
            data_count   <= data_count_next;
            done_reg     <= done_next;
            checksum_reg <= checksum_next;
        end
    end

    always @(*) begin
        n_state         = c_state;
        t_count_next    = t_count_reg;
        dht11_next      = dht11_reg;
        io_en_next      = io_en_reg;
        valid_next      = valid_reg;
        data_next       = data_reg;
        data_count_next = data_count;
        done_next       = done_reg;
        checksum_next   = checksum_reg;

        case (c_state)

            IDLE: begin
                dht11_next = 1;
                io_en_next = 1'b1;
                data_count_next = 0;
                if (start) begin
                    n_state = START;
                end
            end

            START: begin
                if (w_tick) begin
                    checksum_next = 0;
                    valid_next = 0;
                    done_next = 0;
                    dht11_next = 0;
                    if (t_count_reg == 1900 - 1) begin
                        n_state = WAIT;
                        t_count_next = 0;
                    end else begin
                        t_count_next = t_count_reg + 1;
                    end
                end
            end

            WAIT: begin
                //출력 high로
                dht11_next = 1;
                if (w_tick) begin
                    if (t_count_reg == 2) begin
                        n_state = SYNC_DOWN;
                        t_count_next = 0;
                        //출력을 입력으로 전환
                        io_en_next = 0;
                    end else begin
                        t_count_next = t_count_reg + 1;
                    end
                end
            end

            SYNC_DOWN: begin  //입력시점 // start가 빠르게 들어올경우 걸림
                if (w_tick) begin
                    if (t_count_reg > 3) begin
                        if (dht11_io) begin
                            n_state = SYNC_UP;
                        end else t_count_next = t_count_reg + 1;
                    end else if (dht11_io) begin
                        n_state = ERROR;
                    end else t_count_next = t_count_reg + 1;
                end
            end

            SYNC_UP: begin
                t_count_next = 0;
                if (w_tick) begin
                    if (!dht11_io) begin
                        n_state = DATA_SYNC;
                    end
                end
            end

            DATA_SYNC: begin
                if (data_count != 40) begin
                    if (w_tick) begin
                        if (dht11_io) begin
                            n_state = DATA_DETECT;
                        end
                    end
                end else n_state = STOP;
            end

            // DATA_DETECT: begin
            //     if (w_tick) begin
            //         if (!dht11_io) begin  //at falling edge 
            //             if (t_count_reg < 5) begin
            //                 data_next[39-data_count] = 0;
            //                 data_count_next = data_count + 1;
            //                 t_count_next = 0;
            //                 n_state = DATA_SYNC;
            //             end else begin
            //                 data_next[39-data_count] = 1;
            //                 data_count_next = data_count + 1;
            //                 t_count_next = 0;
            //                 n_state = DATA_SYNC;
            //             end
            //         end else t_count_next = t_count_reg + 1;  //high state
            //     end
            // end

            DATA_DETECT: begin
                if (w_tick) begin
                    if (dht11_io) begin
                        t_count_next = t_count_reg + 1;
                    end else n_state = DATA_DECISION;
                end
            end

            DATA_DECISION: begin
                if (t_count_reg < 5) begin
                    data_next[39-data_count] = 0;
                    data_count_next = data_count + 1;
                    t_count_next = 0;
                    n_state = DATA_SYNC;
                end else begin
                    data_next[39-data_count] = 1;
                    data_count_next = data_count + 1;
                    t_count_next = 0;
                    n_state = DATA_SYNC;
                end
            end

            STOP: begin
                valid_next = data_reg[39:32] + data_reg[31:24] + data_reg[23:16] + data_reg[15:8];
                done_next = 1;
                checksum_next = (valid_next == data_reg[7:0]);
                if (w_tick) begin
                    if (t_count_reg == 5 - 1) begin
                        n_state = IDLE;
                    end else t_count_next = t_count_reg + 1;
                end
            end

            ERROR: begin
                if (w_tick) n_state = IDLE;
            end
        endcase
    end

endmodule

module tick_gen_10us (
    input  clk,
    input  rst,
    output o_tick
);
    parameter F_CNT = 1000;
    reg [$clog2(F_CNT) -1 : 0] count_reg;
    reg tick_reg;

    assign o_tick = tick_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count_reg <= 0;
            tick_reg  <= 0;
        end else begin
            if (count_reg == F_CNT - 1) begin
                count_reg <= 0;
                tick_reg  <= 1;
            end else begin
                count_reg <= count_reg + 1;
                tick_reg  <= 0;
            end
        end
    end


endmodule

`timescale 1ns / 1ps


module stopwatch_dp (
    input        clk,
    input        rst,
    input        run_stop,
    input        clear,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);
    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;
    wire w_clear = rst | clear;
    wire w_runstop = clk & run_stop;

    time_counter U_MSEC (
        .clk(w_runstop),
        .rst(w_clear),
        .i_tick(w_tick_100hz),
        .o_time(msec),
        .o_tick(w_sec_tick)
    );

    time_counter #(
        .BIT_WIDTH (6),
        .TICK_COUNT(60)
    ) U_SEC (
        .clk(w_runstop),
        .rst(w_clear),
        .i_tick(w_sec_tick),
        .o_time(sec),
        .o_tick(w_min_tick)
    );

    time_counter #(
        .BIT_WIDTH (6),
        .TICK_COUNT(60)
    ) U_MIN (
        .clk(w_runstop),
        .rst(w_clear),
        .i_tick(w_min_tick),
        .o_time(min),
        .o_tick(w_hour_tick)
    );
    time_counter #(
        .BIT_WIDTH (5),
        .TICK_COUNT(24)
    ) U_HOUR (
        .clk(w_runstop),
        .rst(w_clear),
        .i_tick(w_hour_tick),
        .o_time(hour),
        .o_tick()
    );
    tick_gen_100hz U_tick_gen (
        .clk(w_runstop),
        .rst(w_clear),
        .o_tick_100(w_tick_100hz)
    );
endmodule

module tick_gen_100hz (
    input clk,
    input rst,
    output reg o_tick_100
);
    parameter FCOUNT = 1_000_000;
    // parameter FCOUNT = 10; //simulation

    //fsm stopwatch
    reg [$clog2(FCOUNT)-1 : 0] count_reg;

    //state register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count_reg  <= 0;
            o_tick_100 <= 0;
        end else begin
            if (count_reg == FCOUNT - 1) begin
                o_tick_100 <= 1'b1; //카운트 값이 일치했을때, o_tick을 상승
                count_reg <= 0;
            end else begin
                o_tick_100 <= 1'b0;
                count_reg  <= count_reg + 1;
            end
        end
    end

endmodule

module time_counter #(
    parameter BIT_WIDTH = 7,
    TICK_COUNT = 100,  //현재 msec단위(0~99)
    INITIAL_VALUE = 0
) (
    input clk,
    input rst,
    input i_tick,
    output [BIT_WIDTH-1:0] o_time,
    output o_tick
);

    reg [$clog2(TICK_COUNT)-1:0] count_reg, count_next;
    reg o_tick_reg, o_tick_next;
    assign o_time = count_reg;
    assign o_tick = o_tick_reg;

    // state register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count_reg  <= INITIAL_VALUE;
            o_tick_reg <= 0;
        end else begin
            count_reg  <= count_next;
            o_tick_reg <= o_tick_next;
        end
    end

    //next state(조합논리)
    always @(*) begin
        count_next  = count_reg;
        o_tick_next = o_tick_reg;
        o_tick_next = 1'b0;  //맨밑 else문 제거
        if (i_tick) begin
            if (count_reg == (TICK_COUNT - 1)) begin
                count_next  = 0;
                o_tick_next = 1'b1;
            end else begin
                count_next  = count_reg + 1;
                o_tick_next = 1'b0;
            end
        end 


    end
endmodule



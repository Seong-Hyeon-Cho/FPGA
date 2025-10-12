`timescale 1ns / 1ps

module watch_dp (  //시계, 멈추면 안됨
    input clk,
    input rst,
    // input        sw,
    input btn_time_up,
    input btn_time_down,
    input [7:0] uart_rx,
    input uart_rx_done,
    // input mode,
    input [1:0] field_sel,  // From CU, 00: msec, 01: sec, 10: min, 11: hour
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);
    wire w_tick_100hz, w_sec_tick, w_min_tick, w_hour_tick;

    wire w_msec_up,w_msec_down,w_sec_up,w_sec_down,w_min_up,w_min_down,w_hour_up,w_hour_down;
    wire w_msec_dec_tick, w_sec_dec_tick, w_min_dec_tick;

    watch_counter #() U_MSEC (
        .clk(clk),
        .rst(rst),
        .i_tick(w_tick_100hz),
        .i_dec_tick(),
        .time_up(w_msec_up),
        .time_down(w_msec_down),
        .o_time(msec),
        .o_dec_tick(w_msec_dec_tick),
        .o_tick(w_sec_tick)
    );

    watch_counter #(
        .BIT_WIDTH (6),
        .TICK_COUNT(60)
    ) U_SEC (
        .clk(clk),
        .rst(rst),
        .i_tick(w_sec_tick),
        .i_dec_tick(w_msec_dec_tick),
        .time_up(w_sec_up),
        .time_down(w_sec_down),
        .o_time(sec),
        .o_dec_tick(w_sec_dec_tick),
        .o_tick(w_min_tick)
    );

    watch_counter #(
        .BIT_WIDTH (6),
        .TICK_COUNT(60)
    ) U_MIN (
        .clk(clk),
        .rst(rst),
        .i_tick(w_min_tick),
        .i_dec_tick(w_sec_dec_tick),
        .time_up(w_min_up),
        .time_down(w_min_down),
        .o_time(min),
        .o_dec_tick(w_min_dec_tick),
        .o_tick(w_hour_tick)
    );
    watch_counter #(
        .BIT_WIDTH(5),
        .INITIAL_VALUE(12),
        .TICK_COUNT(24)

    ) U_HOUR (
        .clk(clk),
        .rst(rst),
        .i_tick(w_hour_tick),
        .i_dec_tick(w_min_dec_tick),
        .time_up(w_hour_up),
        .time_down(w_hour_down),
        .o_time(hour),
        .o_dec_tick(),
        .o_tick()
    );
    tick_gen_100hz U_tick_gen (
        .clk(clk),
        .rst(rst),
        .o_tick_100(w_tick_100hz)
    );
    time_updown U_TIME_UPDOWN (
        .field_sel(field_sel),
        .time_up(btn_time_up),
        .time_down(btn_time_down),
        .uart_rx(uart_rx),
        .uart_rx_done(uart_rx_done),
        .msec_up(w_msec_up),
        .msec_down(w_msec_down),
        .sec_up(w_sec_up),
        .sec_down(w_sec_down),
        .min_up(w_min_up),
        .min_down(w_min_down),
        .hour_up(w_hour_up),
        .hour_down(w_hour_down)
    );


endmodule

module time_updown (
    input [1:0] field_sel,
    input time_up,
    input time_down,
    input uart_rx_done,
    input [7:0] uart_rx,
    output msec_up,
    output msec_down,
    output sec_up,
    output sec_down,
    output min_up,
    output min_down,
    output hour_up,
    output hour_down
);

    reg
        r_msec_up,
        r_msec_down,
        r_sec_up,
        r_sec_down,
        r_min_up,
        r_min_down,
        r_hour_up,
        r_hour_down;
    reg uart_time_up, uart_time_down;

    assign msec_up = r_msec_up;
    assign msec_down = r_msec_down;
    assign sec_up = r_sec_up;
    assign sec_down = r_sec_down;
    assign min_up = r_min_up;
    assign min_down = r_min_down;
    assign hour_up = r_hour_up;
    assign hour_down = r_hour_down;

    always @(*) begin
        r_msec_up = 0;
        r_msec_down = 0;
        r_sec_up = 0;
        r_sec_down = 0;
        r_min_up = 0;
        r_min_down = 0;
        r_hour_up = 0;
        r_hour_down = 0;
        uart_time_down = 0;
        uart_time_up = 0;
        if (uart_rx_done) begin
            if ((uart_rx == 8'h55) | (uart_rx == 8'h75)) begin
                uart_time_up = 1;
            end else if ((uart_rx == 8'h44) | (uart_rx == 8'h64)) begin
                uart_time_down = 1;
            end
        end
        case (field_sel)
            2'b00: begin
                r_msec_up   = time_up | uart_time_up;
                r_msec_down = time_down | uart_time_down;
            end
            2'b01: begin
                r_sec_up   = time_up | uart_time_up;
                r_sec_down = time_down | uart_time_down;
            end
            2'b10: begin
                r_min_up   = time_up | uart_time_up;
                r_min_down = time_down | uart_time_down;
            end
            2'b11: begin
                r_hour_up   = time_up | uart_time_up;
                r_hour_down = time_down | uart_time_down;
            end
        endcase
    end

endmodule

module watch_counter #(
    parameter BIT_WIDTH = 7,
    TICK_COUNT = 100,  //현재 msec단위(0~99)
    INITIAL_VALUE = 0
) (
    input clk,
    input rst,
    input i_tick,
    input time_up,
    // input btn_time_up,
    // input btn_time_down,
    input time_down,
    input i_dec_tick,
    output [BIT_WIDTH-1:0] o_time,
    output o_dec_tick,
    output o_tick
);

    // wire time_up, time_down;

    // reg uart_time_up, uart_time_down, uart_time_up_next, uart_time_down_next;
    reg [$clog2(TICK_COUNT)-1:0] count_reg, count_next;
    reg o_tick_reg, o_tick_next;
    reg o_dec_tick_reg, o_dec_tick_next;

    // or (time_up, btn_time_up, uart_time_up);
    // or (time_down, btn_time_down, uart_time_down);

    assign o_time = count_reg;
    assign o_tick = o_tick_reg;
    assign o_dec_tick = o_dec_tick_reg;

    // state register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count_reg <= INITIAL_VALUE;
            o_tick_reg <= 0;
            o_dec_tick_reg <= 0;
            // uart_time_down <= 0;
            // uart_time_up <= 0;
        end else begin
            count_reg <= count_next;
            o_tick_reg <= o_tick_next;
            o_dec_tick_reg <= o_dec_tick_next;
            // uart_time_down <= uart_time_down_next;
            // uart_time_up <= uart_time_up_next;
        end
    end

    //next state(조합논리)
    always @(*) begin
        // uart_time_up_next   = 0;
        // uart_time_down_next = 0;

        // if (uart_rx_done) begin
        //     if ((uart_rx == 8'h55) | (uart_rx == 8'h75)) begin
        //         uart_time_up_next = 1;
        //     end else if ((uart_rx == 8'h44) | (uart_rx == 8'h64)) begin
        //         uart_time_down_next = 1;
        // end
        // end
        count_next = count_reg;
        o_tick_next = o_tick_reg;
        o_tick_next = 1'b0;  //맨밑 else문 제거
        o_dec_tick_next = 1'b0;
        if (i_tick || time_up) begin
            if (count_reg == (TICK_COUNT - 1)) begin
                count_next  = 0;
                o_tick_next = 1'b1;
            end else begin
                count_next  = count_reg + 1;
                o_tick_next = 1'b0;
            end
        end

        if (time_down || i_dec_tick) begin
            if (count_reg == 0) begin
                count_next = TICK_COUNT - 1;
                o_dec_tick_next = 1'b1;
            end else begin  //00에서 -1
                count_next = count_reg - 1;
                o_dec_tick_next = 1'b0;
            end
        end

    end
endmodule

`timescale 1ns / 1ps

module total_watch (
    input        clk,
    input        rst,
    input  [1:0] sw,
    input  [7:0] uart_rx,
    input        uart_rx_done,
    input        btnU,
    input        btnD,
    input        btnL,
    input        btnR,
    output [3:0] led,
    output [7:0] fnd_data,
    output [3:0] fnd_com
);


    wire [6:0] w_stopwatch_msec, w_watch_msec, w_mode_msec;
    wire [5:0] w_stopwatch_sec, w_watch_sec, w_mode_sec;
    wire [5:0] w_stopwatch_min, w_watch_min, w_mode_min;
    wire [4:0] w_stopwatch_hour, w_watch_hour, w_mode_hour;
    wire w_watch_btnU, w_watch_btnD, w_watch_btnL, w_watch_btnR;
    wire w_stopwatch_btnL, w_stopwatch_btnR;
    wire [1:0] w_mode;


    reg  [3:0] r_led;
    assign led = r_led;

    always @(*) begin
        case (w_mode)
            2'b00: r_led = 4'b0101;  //시계 s:ms
            2'b01: r_led = 4'b1001;  //시계 h:m
            2'b10: r_led = 4'b0110;  //타이머 s:ms
            2'b11: r_led = 4'b1010;  //타이머 h:m
        endcase

    end



    fnd_controllr U_FND_CNTR (
        .clk(clk),
        .reset(rst),
        .msec(w_mode_msec),
        .sec(w_mode_sec),
        .min(w_mode_min),
        .hour(w_mode_hour),
        .mode0(w_mode[0:0]),
        .fnd_data(fnd_data),
        .fnd_com(fnd_com)
    );

    top_stopwatch U_STOPWATCH (
        .clk(clk),
        .rst(rst),
        .btnR_Clear(w_stopwatch_btnR),
        .btnL_RunStop(w_stopwatch_btnL),
        .uart_rx(uart_rx),
        .uart_rx_done(uart_rx_done),
        .msec(w_stopwatch_msec),
        .sec(w_stopwatch_sec),
        .min(w_stopwatch_min),
        .hour(w_stopwatch_hour)
    );

    top_watch U_WATCH (
        .clk(clk),
        .rst(rst),
        .btnU_timeup(w_watch_btnU),
        .btnD_timedown(w_watch_btnD),
        .btnL_shift_left(w_watch_btnL),
        .btnR_shift_right(w_watch_btnR),
        .sw(w_mode[0:0]),
        .uart_rx(uart_rx),
        .uart_rx_done(uart_rx_done),
        .msec(w_watch_msec),
        .sec(w_watch_sec),
        .min(w_watch_min),
        .hour(w_watch_hour)
    );

    mode_out U_MODE_DISPLAY (

        .mode1(w_mode[1:1]),
        .stopwatch_msec(w_stopwatch_msec),
        .stopwatch_sec(w_stopwatch_sec),
        .stopwatch_min(w_stopwatch_min),
        .stopwatch_hour(w_stopwatch_hour),
        .watch_msec(w_watch_msec),
        .watch_sec(w_watch_sec),
        .watch_min(w_watch_min),
        .watch_hour(w_watch_hour),
        .msec(w_mode_msec),
        .sec(w_mode_sec),
        .min(w_mode_min),
        .hour(w_mode_hour)
    );

    BTN_CONNECT U_BTN_CONNECT (
        .clk(clk),
        .rst(rst),
        .btnU(btnU),
        .btnD(btnD),
        .btnL(btnL),
        .btnR(btnR),
        .mode1(w_mode[1:1]),
        .o_watch_btnU(w_watch_btnU),
        .o_watch_btnD(w_watch_btnD),
        .o_watch_btnL(w_watch_btnL),
        .o_watch_btnR(w_watch_btnR),
        .o_stopwatch_btnL(w_stopwatch_btnL),
        .o_stopwatch_btnR(w_stopwatch_btnR)
    );

    wire sw0_pos_edge, sw1_pos_edge, sw0_neg_edge, sw1_neg_edge;
    MODE U_MODE_CONTROL (
        .clk(clk),
        .rst(rst),
        .sw0_pos_edge(sw0_pos_edge),
        .sw1_pos_edge(sw1_pos_edge),
        .uart_rx(uart_rx),
        .uart_rx_done(uart_rx_done),
        .mode(w_mode)
    );


    // sw_debounce_edge db0 (
    //     .clk(clk),
    //     .rst(rst),
    //     .sw_in(sw[0]),
    //     // .neg_edge_flag(sw0_neg_edge),
    //     .pos_edge_flag(sw0_pos_edge)
    // );

    // sw_debounce_edge db1 (
    //     .clk(clk),
    //     .rst(rst),
    //     .sw_in(sw[1]),
    //     // .neg_edge_flag(sw1_neg_edge),
    //     .pos_edge_flag(sw1_pos_edge)
    // );
    btn_debounce sw0_db(
    .clk(clk),
    .rst(rst),
    .i_btn(sw[0]),
    .o_btn(sw0_pos_edge)
);

    btn_debounce sw1_db(
    .clk(clk),
    .rst(rst),
    .i_btn(sw[1]),
    .o_btn(sw1_pos_edge)
);
    // sw_uart_state U_sw_state(
    //     .clk(clk),
    //     .rst(rst), 
    //     .sw(sw), 
    //     .uart_rx(uart_rx),
    //     .uart_rx_done(uart_rx_done),
    //     .mode(w_mode)
    // );
endmodule

module mode_out (  //시계/스톱워치 + 표기시간 을 모드로 출력
    input mode1,
    input [6:0] stopwatch_msec,
    input [5:0] stopwatch_sec,
    input [5:0] stopwatch_min,
    input [4:0] stopwatch_hour,
    input [6:0] watch_msec,
    input [5:0] watch_sec,
    input [5:0] watch_min,
    input [4:0] watch_hour,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);

    reg [6:0] r_mode_msec;
    reg [5:0] r_mode_sec;
    reg [5:0] r_mode_min;
    reg [4:0] r_mode_hour;

    assign msec = r_mode_msec;
    assign sec  = r_mode_sec;
    assign min  = r_mode_min;
    assign hour = r_mode_hour;

    always @(*) begin
        case (mode1)
            1: begin
                r_mode_msec = stopwatch_msec;
                r_mode_sec  = stopwatch_sec;
                r_mode_min  = stopwatch_min;
                r_mode_hour = stopwatch_hour;
            end
            0: begin
                r_mode_msec = watch_msec;
                r_mode_sec  = watch_sec;
                r_mode_min  = watch_min;
                r_mode_hour = watch_hour;
            end
        endcase

    end
endmodule

// module MODE (
//     input clk,
//     input rst,
//     input [1:0] sw,
//     input [7:0] uart_rx,
//     input uart_rx_done,
//     output [1:0] mode
// );
//     localparam M = 8'h4d, m = 8'h6d, N = 8'h4e, n = 8'h6e;

//     reg WATCH = 0, STOPWATCH = 1;
//     reg SEC_MSEC = 0, HOUR_MIN = 1;
//     reg [1:0] c_state, n_state;
//     // reg uart_sw1, uart_sw0;  //sw1: 시계/타이머, sw0:표기 시간간

//     assign mode = c_state;
//     // or
//     always @(posedge clk or posedge rst) begin
//         if (rst) begin
//             c_state  <= 2'b00;
//             // uart_sw0 <= 0;
//             // uart_sw1 <= 0;
//         end else c_state <= n_state;
//         // if (uart_rx_done) begin
//         //     if ((uart_rx == N) | (uart_rx == n)) begin
//         //         uart_sw0 <= 1;
//         //     end else if ((uart_rx == M) | (uart_rx == m)) begin
//         //         uart_sw1 <= 1;
//         //     end
//         // end else begin
//         //     uart_sw0 <= 0;
//         //     uart_sw1 <= 0;
//         // end
//     end

//     // always @(*) begin
//     //     uart_sw0 = 0;
//     //     uart_sw1 = 0;
//     //     if (uart_rx_done) begin
//     //         if ((uart_rx == N) | (uart_rx == n)) begin
//     //             uart_sw0 = 1;
//     //         end else if ((uart_rx == M) | (uart_rx == m)) begin
//     //             uart_sw1 = 1;
//     //         end
//     //     // end else begin
//     //     //     uart_sw0 = 0;
//     //     //     uart_sw1 = 0;
//     //     end
//     // end
//     reg uart_sw0_reg, uart_sw1_reg;

// always @(posedge clk or posedge rst) begin
//     if (rst) begin
//         uart_sw0_reg <= 0;
//         uart_sw1_reg <= 0;
//     end else begin
//         uart_sw0_reg <= uart_rx_done && ((uart_rx == N) || (uart_rx == n));
//         uart_sw1_reg <= uart_rx_done && ((uart_rx == M) || (uart_rx == m));
//     end
// end
//         always @(*) begin
//                     n_state = c_state;
//         case (c_state)
//             // {
//             //     WATCH, SEC_MSEC
//             // } : begin  //00
//             //     if (sw == 2'b01) begin
//             //         n_state = {WATCH, HOUR_MIN};
//             //     end else if (sw == 2'b10) begin
//             //         n_state = {STOPWATCH, SEC_MSEC};
//             //         // end else if (uart_rx_done) begin
//             //     end
//             //     if (uart_rx_done) begin
//             //         if ((uart_rx == N) | (uart_rx == n)) begin
//             //             n_state = {WATCH, HOUR_MIN};
//             //         end else if ((uart_rx == M) | (uart_rx == m)) begin
//             //             n_state = {STOPWATCH, SEC_MSEC};
//             //         end
//             //     end
//             // end
//             {
//                 WATCH, SEC_MSEC
//             } : begin  //00
//                 if (sw == 2'b01 | uart_sw0_reg) n_state = {WATCH, HOUR_MIN};
//                 else if (sw == 2'b10 | uart_sw1_reg)
//                     n_state = {STOPWATCH, SEC_MSEC};
//             end
//             {
//                 WATCH, HOUR_MIN
//             } : begin  //01
//                             if (sw == 2'b00 | uart_sw0_reg) n_state = {WATCH, SEC_MSEC};
//                 else if (sw == 2'b11 | uart_sw1_reg)
//                     n_state = {STOPWATCH, HOUR_MIN};
//             end
//             {
//                 WATCH, HOUR_MIN
//             } : begin  //01
//                 if (sw == 2'b00) begin
//                     n_state = {WATCH, SEC_MSEC};
//                 end else if (sw == 2'b11) begin
//                     n_state = {STOPWATCH, HOUR_MIN};
//                     // end else if (uart_rx_done) begin
//                 end
//                 if (uart_rx_done) begin
//                     if ((uart_rx == N) | (uart_rx == n)) begin
//                         n_state = {WATCH, SEC_MSEC};
//                     end else if ((uart_rx == M) | (uart_rx == m)) begin
//                         n_state = {STOPWATCH, HOUR_MIN};
//                     end
//                 end
//             end
//             {
//                 STOPWATCH, SEC_MSEC
//             } : begin  //10
//                 if (sw == 2'b11) begin
//                     n_state = {STOPWATCH, HOUR_MIN};
//                 end else if (sw == 2'b00) begin
//                     n_state = {WATCH, SEC_MSEC};
//                     // end else if (uart_rx_done) begin
//                 end
//                 if (uart_rx_done) begin
//                     if ((uart_rx == N) | (uart_rx == n)) begin
//                         n_state = {STOPWATCH, HOUR_MIN};
//                     end else if ((uart_rx == M) | (uart_rx == m)) begin
//                         n_state = {WATCH, SEC_MSEC};
//                     end
//                 end
//             end
//             {
//                 STOPWATCH, HOUR_MIN
//             } : begin  //11
//                 if (sw == 2'b10) begin
//                     n_state = {STOPWATCH, SEC_MSEC};
//                 end else if (sw == 2'b01) begin
//                     n_state = {WATCH, HOUR_MIN};
//                     // end else if (uart_rx_done) begin
//                 end
//                 if (uart_rx_done) begin
//                     if ((uart_rx == N) | (uart_rx == n)) begin
//                         n_state = {STOPWATCH, SEC_MSEC};
//                     end else if ((uart_rx == M) | (uart_rx == m)) begin
//                         n_state = {WATCH, HOUR_MIN};
//                     end
//                 end
//             end

//         endcase
//     end
// endmodule

// module MODE (
//     input clk,
//     input rst,
//     input [1:0] sw,
//     input [7:0] uart_rx,
//     input uart_rx_done,
//     output [1:0] mode
// );
//     localparam M = 8'h4d, m = 8'h6d, N = 8'h4e, n = 8'h6e;

//     parameter WATCH = 1'b0, STOPWATCH = 1'b1;
//     parameter SEC_MSEC = 1'b0, HOUR_MIN = 1'b1;
//     reg [1:0] c_state, n_state;

//     assign mode = c_state;

//     // UART 신호 latch
//     reg uart_sw0_reg, uart_sw1_reg;

//     always @(posedge clk or posedge rst) begin
//         if (rst) begin
//             c_state <= 2'b00;
//         end else begin
//             c_state <= n_state;
//         end
//     end

//     always @(posedge clk or posedge rst) begin
//         if (rst) begin
//             uart_sw0_reg <= 0;
//             uart_sw1_reg <= 0;
//         end else begin
//             uart_sw0_reg <= uart_rx_done && ((uart_rx == N) || (uart_rx == n));
//             uart_sw1_reg <= uart_rx_done && ((uart_rx == M) || (uart_rx == m));
//         end
//     end

//     always @(*) begin
//         n_state = c_state;
//         case (c_state)
//             {
//                 WATCH, SEC_MSEC
//             } : begin  // 00
//                 if (sw == 2'b01 || uart_sw0_reg) n_state = {WATCH, HOUR_MIN};
//                 else if (sw == 2'b10 || uart_sw1_reg)
//                     n_state = {STOPWATCH, SEC_MSEC};
//             end

//             {
//                 WATCH, HOUR_MIN
//             } : begin  // 01
//                 if (sw == 2'b00 || uart_sw0_reg) n_state = {WATCH, SEC_MSEC};
//                 else if (sw == 2'b11 || uart_sw1_reg)
//                     n_state = {STOPWATCH, HOUR_MIN};
//             end

//             {
//                 STOPWATCH, SEC_MSEC
//             } : begin  // 10
//                 if (sw == 2'b11 || uart_sw0_reg)
//                     n_state = {STOPWATCH, HOUR_MIN};
//                 else if (sw == 2'b00 || uart_sw1_reg)
//                     n_state = {WATCH, SEC_MSEC};
//             end

//             {
//                 STOPWATCH, HOUR_MIN
//             } : begin  // 11
//                 if (sw == 2'b10 || uart_sw0_reg)
//                     n_state = {STOPWATCH, SEC_MSEC};
//                 else if (sw == 2'b01 || uart_sw1_reg)
//                     n_state = {WATCH, HOUR_MIN};
//             end
//         endcase
//     end
// endmodule

// module sw_uart_state (
//     input clk,
//     input rst,
//     // input sw0,
//     // input sw1,
//     input [1:0] sw,
//     // input i_uart_sw0,
//     // input i_uart_sw1,
//     input [7:0] uart_rx,
//     input uart_rx_done,
//     // output o_sw0,
//     // output o_sw1
//     output [1:0] mode
// );
//     localparam M = 8'h4d, m = 8'h6d, N = 8'h4e, n = 8'h6e;
//     parameter WATCH = 0, STOPWATCH = 1;
//     parameter SEC_MSEC = 0, HOUR_MIN = 1;
//     reg [1:0] c_state, n_state;
//     reg i_uart_sw0, i_uart_sw1;

//     reg
//         sw0_pre,
//         sw1_pre,
//         uart_sw0_pre,
//         uart_sw1_pre,
//         edge_sw0,
//         edge_sw1,
//         u_edge_sw0,
//         u_edge_sw1;

//     always @(*) begin
//         i_uart_sw0 = 0;
//         i_uart_sw1 = 0;
//         if (uart_rx_done) begin
//             if (uart_rx == N | uart_rx == n) begin
//                 i_uart_sw0 = 1;
//             end else if (uart_rx == M || uart_rx == m) begin
//                 i_uart_sw1 = 1;
//             end
//         end
//     end

//     always @(posedge clk, posedge rst) begin
//         if (rst) begin
//             sw0_pre <= 0;
//             sw1_pre <= 0;
//             uart_sw0_pre <= 0;
//             uart_sw1_pre <= 0;
//             c_state <= 2'b00;
//         end else begin
//             edge_sw0 <= sw[0] ^ sw0_pre;
//             edge_sw1 <= sw[1] ^ sw1_pre;
//             u_edge_sw0 <= i_uart_sw0 ^ uart_sw0_pre;
//             u_edge_sw1 <= i_uart_sw1 ^ uart_sw1_pre;

//             sw0_pre <= sw[0];
//             sw1_pre <= sw[1];
//             uart_sw0_pre <= i_uart_sw0;
//             uart_sw1_pre <= i_uart_sw1;
//             c_state <= n_state;
//         end
//     end

//     // assign o_sw0 = c_state[0];  // SEC_MSEC(0)/HOUR_MIN(1)
//     // assign o_sw1 = c_state[1];  // WATCH(0)/STOPWATCH(1)
// assign mode = c_state;
//     always @(*) begin
//         n_state = c_state;
//         case (c_state)
//             {
//                 WATCH, SEC_MSEC
//             } : begin
//                 if (edge_sw0 && sw[0] == 1) n_state = {WATCH, HOUR_MIN};
//                 else if (edge_sw1 && sw[1] == 1)
//                     n_state = {STOPWATCH, SEC_MSEC};
//                 else if (u_edge_sw0 && i_uart_sw0 == 1)
//                     n_state = {WATCH, HOUR_MIN};
//                 else if (u_edge_sw1 && i_uart_sw1 == 1)
//                     n_state = {STOPWATCH, SEC_MSEC};

//             end
//             {
//                 WATCH, HOUR_MIN
//             } : begin
//                 if (edge_sw0 && sw[0] == 0) n_state = {WATCH, SEC_MSEC};
//                 else if (edge_sw1 && sw[1] == 1)
//                     n_state = {STOPWATCH, SEC_MSEC};
//                 else if (u_edge_sw0 && i_uart_sw0 == 1)
//                     n_state = {WATCH, SEC_MSEC};
//                 else if (u_edge_sw1 && i_uart_sw1 == 1)
//                     n_state = {STOPWATCH, SEC_MSEC};

//             end
//             {
//                 STOPWATCH, SEC_MSEC
//             } : begin
//                 if (edge_sw0 && sw[0] == 0) n_state = {STOPWATCH, HOUR_MIN};
//                 else if (edge_sw1 && sw[1] == 1) n_state = {WATCH, SEC_MSEC};
//                 else if (u_edge_sw0 && i_uart_sw0 == 1)
//                     n_state = {STOPWATCH, HOUR_MIN};
//                 else if (u_edge_sw1 && i_uart_sw1 == 1)
//                     n_state = {WATCH, SEC_MSEC};

//             end
//             {
//                 STOPWATCH, HOUR_MIN
//             } : begin
//                 if (edge_sw0 && sw[0] == 0) n_state = {STOPWATCH, SEC_MSEC};
//                 else if (edge_sw1 && sw[1] == 1) n_state = {WATCH, HOUR_MIN};
//                 else if (u_edge_sw0 && i_uart_sw0 == 1)
//                     n_state = {STOPWATCH, SEC_MSEC};
//                 else if (u_edge_sw1 && i_uart_sw1 == 1)
//                     n_state = {WATCH, HOUR_MIN};

//             end
//         endcase
//     end
// endmodule
// module MODE (
//     input clk,
//     input rst,
//     // input [1:0] sw,
//     input sw0_pos_edge,
//     input sw0_neg_edge,
//     input sw1_pos_edge,
//     input sw1_neg_edge,
//     input [7:0] uart_rx,
//     input uart_rx_done,
//     output [1:0] mode
// );

//     localparam M = 8'h4d, m = 8'h6d, N = 8'h4e, n = 8'h6e;

//     localparam WATCH = 1'b0, STOPWATCH = 1'b1;
//     localparam SEC_MSEC = 1'b0, HOUR_MIN = 1'b1;

//     reg [1:0] c_state, n_state;

//     // 스위치 이전 값 저장
//     reg [1:0] sw_prev;
//     // wire sw0_edge = (sw[0] && !sw_prev[0]);  // 상승 에지
//     // wire sw1_edge = (sw[1] && !sw_prev[1]);  // 상승 에지

//     // 1클럭 플래그
//     reg sw0_flag, sw1_flag;

//     // UART 플래그 latch
//     reg uart_sw0_flag, uart_sw1_flag;


//     // 현재 상태 저장
//     always @(posedge clk or posedge rst) begin
//         if (rst) begin
//             c_state <= {WATCH, SEC_MSEC};
//             uart_sw0_flag <= 0;
//             uart_sw1_flag <= 0;
//         end else begin
//             c_state <= n_state;

//             // 새로운 UART 명령이 들어왔을 때만 플래그 설정
//             if (uart_rx_done) begin
//                 if (uart_rx == N || uart_rx == n) uart_sw0_flag <= 1;
//                 else if (uart_rx == M || uart_rx == m) uart_sw1_flag <= 1;
//             end else begin
//                 // 상태 전이가 발생하면 플래그 클리어
//                 if (n_state != c_state) begin
//                     uart_sw0_flag <= 0;
//                     uart_sw1_flag <= 0;
//                 end
//             end
//         end
//     end


//     // 상태 전이 FSM
//     always @(*) begin
//         n_state = c_state;
//         case (c_state)
//             {
//                 WATCH, SEC_MSEC
//             } : begin  //00
//                 if (sw0_pos_edge || uart_sw0_flag) n_state = {WATCH, HOUR_MIN};
//                 // if (uart_sw0_flag) n_state = {WATCH, HOUR_MIN};
//                 // else if (uart_sw1_flag)
//                 else if (sw1_pos_edge || uart_sw1_flag)
//                     n_state = {STOPWATCH, SEC_MSEC};
//                     // else if ()
//             end
//             {
//                 WATCH, HOUR_MIN
//             } : begin  //01
//                 if (sw0_neg_edge || uart_sw0_flag) n_state = {WATCH, SEC_MSEC};
//                 // if (uart_sw0_flag) n_state = {WATCH, SEC_MSEC};
//                 else if (sw1_pos_edge || uart_sw1_flag)
//                     // else if (uart_sw1_flag)
//                     n_state = {
//                         STOPWATCH, HOUR_MIN
//                     };
//             end
//             {
//                 STOPWATCH, SEC_MSEC
//             } : begin  //10
//                 if (sw0_pos_edge || uart_sw0_flag)
//                     // if (uart_sw0_flag)
//                     n_state = {
//                         STOPWATCH, HOUR_MIN
//                     };
//                 else if (sw1_neg_edge || uart_sw1_flag)
//                     // else if (uart_sw1_flag)
//                     n_state = {
//                         WATCH, SEC_MSEC
//                     };
//             end
//             {
//                 STOPWATCH, HOUR_MIN
//             } : begin  //11
//                 if (sw0_neg_edge || uart_sw0_flag)
//                     // if (uart_sw0_flag)
//                     n_state = {
//                         STOPWATCH, SEC_MSEC
//                     };
//                 else if (sw1_neg_edge || uart_sw1_flag)
//                     // else if (uart_sw1_flag)
//                     n_state = {
//                         WATCH, HOUR_MIN
//                     };
//                     // else if ()
//             end
//         endcase
//     end

//     assign mode = c_state;

// endmodule


module MODE (
    input clk,
    input rst,
    input sw0_pos_edge,
    input sw1_pos_edge,
    // input [1:0] sw,
    input [7:0] uart_rx,
    input uart_rx_done,
    output [1:0] mode
);

    localparam M = 8'h4d, m = 8'h6d, N = 8'h4e, n = 8'h6e;

    localparam WATCH = 1'b0, STOPWATCH = 1'b1;
    localparam SEC_MSEC = 1'b0, HOUR_MIN = 1'b1;

    reg [1:0] c_state, n_state;
    
    // // 스위치 이전 값 저장
    // reg [1:0] sw_prev;
    // // wire sw0_edge = (sw[0] && !sw_prev[0]);  // 상승 에지
    // // wire sw1_edge = (sw[1] && !sw_prev[1]);  // 상승 에지

    // UART 플래그 latch
    reg uart_sw0_flag, uart_sw1_flag;
    // // 1클럭 플래그
    // reg sw0_flag, sw1_flag;

    // 현재 상태 저장
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state <= {WATCH, SEC_MSEC};
            uart_sw0_flag <= 0;
            uart_sw1_flag <= 0;
        end else begin
            c_state <= n_state;

            // 새로운 UART 명령이 들어왔을 때만 플래그 설정
            if (uart_rx_done) begin
                if (uart_rx == N || uart_rx == n) uart_sw0_flag <= 1;
                else if (uart_rx == M || uart_rx == m) uart_sw1_flag <= 1;
            end else begin
                // 상태 전이가 발생하면 플래그 클리어
                if (n_state != c_state) begin
                    uart_sw0_flag <= 0;
                    uart_sw1_flag <= 0;
                end
            end
        end
    end

    // 상태 전이 FSM
    always @(*) begin
        n_state = c_state;
        case (c_state)

            {WATCH, SEC_MSEC} : begin  //00
                if (sw0_pos_edge || uart_sw0_flag) n_state = {WATCH, HOUR_MIN};
                else if (sw1_pos_edge || uart_sw1_flag)
                    n_state = {STOPWATCH, SEC_MSEC};
            end

            {WATCH, HOUR_MIN} : begin  //01
                if (sw0_pos_edge || uart_sw0_flag) n_state = {WATCH, SEC_MSEC};

                else if (sw1_pos_edge || uart_sw1_flag)
                    n_state = {STOPWATCH, HOUR_MIN};
            end

            {STOPWATCH, SEC_MSEC} : begin  //10
                if (sw0_pos_edge || uart_sw0_flag)
                    n_state = {STOPWATCH, HOUR_MIN};
                else if (sw1_pos_edge || uart_sw1_flag)
                    n_state = {WATCH, SEC_MSEC};
            end

            {STOPWATCH, HOUR_MIN} : begin  //11
                if (sw0_pos_edge || uart_sw0_flag)
                    n_state = {STOPWATCH, SEC_MSEC};
                else if (sw1_pos_edge || uart_sw1_flag)
                    n_state = {WATCH, HOUR_MIN};
            end
        endcase
    end

    assign mode = c_state;

endmodule

module sw_debounce_edge (
    input      clk,
    input      rst,
    input      sw_in,         // 노이즈 있는 스위치 입력
    output reg pos_edge_flag  // 상승 에지에서 1클럭 동안 1

);

    reg [15:0] cnt;
    reg sw_sync, sw_debounced, sw_prev;

    // 1단계: 스위치 동기화 (meta stable 방지용)
    reg sw_sync_0;
    always @(posedge clk) begin
        sw_sync_0 <= sw_in;
        sw_sync   <= sw_sync_0;
    end

    // 2단계: debounce 카운터
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 0;
            sw_debounced <= 0;
        end else if (sw_sync != sw_debounced) begin
            cnt <= cnt + 1;
            if (cnt == 16'hFFFF) sw_debounced <= sw_sync;
        end else begin
            cnt <= 0;
        end
    end

    // 3단계: edge detect (상승 에지)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sw_prev <= 0;
            pos_edge_flag <= 0;
            // neg_edge_flag <= 0;
        end else begin
            pos_edge_flag <= (~sw_prev & sw_debounced);  // 0→1
            // neg_edge_flag <= (sw_prev & ~sw_debounced);  // 1→0
            sw_prev <= sw_debounced;
        end
    end

endmodule















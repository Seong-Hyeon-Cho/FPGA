`timescale 1ns / 1ps


module sr04_controller (
    input         clk,
    input         rst,
    input         start,
    input         echo,
    output        trig,
    output [15:0]  dist,
    output        dist_done
);

wire o_tick;

distance U_distance(
    .clk(clk),
    .rst(rst),
    .echo(echo),
    .i_tick(o_tick),
    .dist(dist),
    .dist_done(dist_done)
);

tick_gen_1Mhz U_tick_gen(
    .clk(clk),
    .rst(rst),
    .o_tick_1mhz(o_tick)
);

start_trigger U_start(
    .clk(clk),
    .rst(rst),
    .i_tick(o_tick),
    .start_btn(start),
    .sr04_tigger(trig)
);

// start_trigger_2 U_signal(
//     .clk(clk),
//     .rst(rst),
//     .i_tick(o_tick),
//     .start_btn(start),
//     .echo(echo),
//     .dist(dist),
//     .dist_done(dist_done),
//     .sr04_tigger(trig)
// );
endmodule

module tick_gen_1Mhz (
    input  clk,
    input  rst,
    output o_tick_1mhz
);


    parameter F_COUNT = (100);  //100_000_000 / 100 = 1_000_000 -> 1Mhz == 1us
    reg [$clog2(F_COUNT) -1 : 0] count_reg;
    reg tick_reg;

    assign o_tick_1mhz = tick_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count_reg <= 0;
            tick_reg  <= 0;
        end else begin
            if (count_reg == F_COUNT) begin
                count_reg <= 0;
                tick_reg  <= 1;
            end else begin
                count_reg <= count_reg + 1;
                tick_reg  <= 0;
            end
        end
    end

endmodule

module start_trigger (
    input  clk,
    input  rst,
    input  i_tick,
    input  start_btn,
    output sr04_tigger
);

    reg sr04_trigg_reg, sr04_trigg_next;
    reg [7:0] count_reg, count_next;
    reg start_reg, start_next;

    assign sr04_tigger = sr04_trigg_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            start_reg      <= 0;
            sr04_trigg_reg <= 0;
            count_reg      <= 0;
            start_reg <=0;
        end else begin
            start_reg      <= start_next;
            sr04_trigg_reg <= sr04_trigg_next;
            count_reg      <= count_next;
        end
    end

    always @(*) begin
        start_next      = start_reg;
        sr04_trigg_next = sr04_trigg_reg;
        count_next      = count_reg;
        case (start_reg)
            0: begin
                count_next = 0;
                sr04_trigg_next = 0;
                if (start_btn) begin
                    start_next = 1;
                end
            end
            1: begin
                if (i_tick) begin
                    sr04_trigg_next = 1;
                    count_next = count_reg + 1;
                    if (count_reg == 10) begin  //1~10
                        start_next = 0;
                    end
                end
            end
        endcase
    end

endmodule

/*
module distance (
    input clk,
    input rst,
    input         echo,
    input i_tick,
    output [15:0] dist,
    output dist_done
);

    reg [15:0] count_reg, count_next;
    reg [15:0] dist_reg,dist_next;

    reg [4:0] echo_reg,echo_next;
        reg echo_d1, echo_d2;

// wire falling_edge_1,falling_edge_2;
wire falling_edge;

    reg dist_done_reg;
// assign falling_edge_1= (echo_d2 == 1) && (echo_d1 == 0);
assign falling_edge = echo_d2 & (~echo_d1);
assign dist_done = dist_done_reg;  //2클럭 뒤에 발생

    always @(posedge clk,posedge rst) begin
        if(rst) begin
            count_reg <=0;
            echo_reg <=0;
            dist_reg <=0;
                    echo_d1 <= 0;
                    dist_done_reg <= 0;
        echo_d2 <= 0;
        end else begin 
            count_reg <= count_next;
            echo_reg <= echo_next;
            dist_reg <= dist_next;
        echo_d1 <= echo;
        echo_d2 <= echo_d1;
        dist_done_reg <= falling_edge;
        end
    end

    always @(echo,echo_reg) begin
        echo_next = {echo,echo_reg[4:1]};
    end

    wire w_dist_done;
    assign w_dist_done = &echo_reg;
    reg r_dist_done;

    always @(posedge clk,posedge rst) begin
        if(rst) r_dist_done <=0;
        else r_dist_done <= w_dist_done;
    end

    // assign dist_done = r_dist_done&(~(w_dist_done)); //다음 클럭에 바로 발생


// always @(posedge clk or posedge rst) begin
//     if (rst) begin
//         echo_d1 <= 0;
//         echo_d2 <= 0;
//     end else begin
//         echo_d1 <= echo;
//         echo_d2 <= echo_d1;
//     end
// end



    // always @(posedge clk or posedge rst) begin
    //     if (rst) begin
    //     dist_done_reg <= 0;
    //     end else dist_done_reg <= falling_edge;
    // end

    always @(*) begin
        count_next = count_reg;
        dist_next = dist_reg;
    
        case(echo)
        0: begin
            count_next = 0;
        end

        1: begin
            if(i_tick) count_next = count_reg +1;
        end
        endcase

    end

    assign dist = dist_reg/58; //cm
    // assign dist = dist_reg;
endmodule
*/

module distance (
    input clk,
    input rst,
    input echo,
    input i_tick,
    output [15:0] dist,
    output dist_done
);

    reg [15:0] count_reg;
    reg [15:0] dist_reg;
    reg dist_done_reg;

    // Edge detection
    reg echo_d1, echo_d2;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            echo_d1 <= 0;
            echo_d2 <= 0;
        end else begin
            echo_d1 <= echo;
            echo_d2 <= echo_d1;
        end
    end

    wire rising_edge  = (echo_d1 == 1) && (echo_d2 == 0);
    wire falling_edge = (echo_d1 == 0) && (echo_d2 == 1);

    // Counter logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count_reg <= 0;
            dist_reg <= 0;
            dist_done_reg <= 0;
        end else if (rising_edge) begin
            count_reg <= 0; // echo 시작 순간부터 카운터 시작
        end else if (echo && i_tick) begin
            count_reg <= count_reg + 1;
            end else if (falling_edge) begin
                dist_reg <= count_reg;
                dist_done_reg <= 1;
                end else begin
                    dist_done_reg <= 0;
        end
    end

    // 거리 저장 및 완료 플래그
    // always @(posedge clk or posedge rst) begin
    //     if (rst) begin
    //         dist_reg <= 0;
    //         dist_done_reg <= 0;
    //     end else if (falling_edge) begin
    //         dist_reg <= count_reg;
    //         dist_done_reg <= 1;
    //     end else begin
    //         dist_done_reg <= 0;
    //     end
    // end

    assign dist = dist_reg / 58; // 거리 계산 (cm)
    assign dist_done = dist_done_reg;

endmodule




module start_trigger_2 (
    input  clk,
    input  rst,
    input  i_tick,
    input  start_btn,
    input echo,
    output [9:0] dist,
    output dist_done,
    output sr04_tigger
);

    reg sr04_trigg_reg, sr04_trigg_next;
    reg [7:0] count_reg, count_next;
    //
    reg [$clog2(400*58)-1:0] dist_count_reg,dist_count_next;
    reg dist_done_reg,dist_done_next;

    //
    reg [1:0] start_reg, start_next;

    assign sr04_tigger = sr04_trigg_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            start_reg      <= 0;
            sr04_trigg_reg <= 0;
            count_reg      <= 0;
            dist_count_reg <=0;
            dist_done_reg <=0;
        end else begin
            start_reg      <= start_next;
            sr04_trigg_reg <= sr04_trigg_next;
            count_reg      <= count_next;
            dist_count_reg <= dist_count_next;
            dist_done_reg  <= dist_done_next;
        end
    end

    always @(*) begin
        dist_count_next = dist_count_reg;
        dist_done_next = dist_done_reg;
        start_next      = start_reg;
        sr04_trigg_next = sr04_trigg_reg;
        count_next      = count_reg;
        case (start_reg)
            0: begin
                count_next = 0;
                sr04_trigg_next = 0;
                dist_done_next = 0;
                if (start_btn) begin
                    start_next = 1;
                end
            end
            1: begin
                if (i_tick) begin
                    sr04_trigg_next = 1;
                    count_next = count_reg + 1;
                    if (count_reg == 10) begin  //1~10
                        start_next = 2;
                        dist_count_next =0;
                    end
                end
            end
            2:begin //dist count
                if(echo&i_tick)begin
                    dist_count_next = dist_count_reg +1;
                //if(dist_count_reg == 58)
                //dist_reg = dist_reg +1;
                end else if(~echo) begin
                    start_next = 3;
                end else begin
                    dist_count_next = dist_count_reg;
                end
            end
            3: begin //dist calcu
                dist_count_next = dist_count_reg /58;
                dist_done_next = 1;
                start_next = 0;
            end
        endcase
    end

    assign dist = dist_count_reg;
    assign dist_done = dist_done_reg;

endmodule
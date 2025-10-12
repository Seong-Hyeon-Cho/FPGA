`timescale 1ns / 1ps

module btn_debounce (
    input  clk,
    input  rst,
    input  i_btn,
    output o_btn
);

    //clk div(100KHz)
    parameter F_COUNT = 1000;
    // parameter F_COUNT = 2;  //simulation
    reg [$clog2(F_COUNT)-1:0] r_counter;

    reg r_clk;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            r_counter <= 0;
            r_clk <= 0;
        end else begin
            if (r_counter == F_COUNT - 1) begin
                r_counter <= 0;
                r_clk <= 1;
            end else begin
                r_counter <= r_counter + 1;  //adder
                r_clk <= 0;
            end
        end
    end

    //debounce
    reg [7:0] q_reg, q_next;
    always @(posedge r_clk, posedge rst) begin
        if (rst) begin
            q_reg <= 0;
        end else begin
            q_reg <= q_next;  //기존값을 다음 값으로 넘김
        end
    end

    //shift register
    always @(i_btn, r_clk, q_reg) begin  //shift 연산 이용
        q_next = {i_btn, q_reg[7:1]};
    end

    //8input and gate
    wire w_debounce;
    assign w_debounce = &q_reg;

    //edge ditection
    reg r_edge_q; //Q5
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            r_edge_q <= 0;
        end else begin
            r_edge_q <= w_debounce;
        end
    end

    //rising edge 
    assign o_btn = ~(r_edge_q) & w_debounce;
    // assign btn_neg = ~w_debounce & (r_edge_q);
endmodule

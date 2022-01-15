`include "defines.svh"

import defines::*;

//
//This module implements the Benes Network algorithm
//used by the Random Modulo in the L1 caches.
//

module benes_network_3
    #(parameter N = 3,
    parameter   CNT = 3)
    (input                clk,
    input                 reset,

    input logic[N-1:0]    word_i,
    input logic[CNT-1:0]  control,   
    output logic[N-1:0]   word_o);

    //Actual code
    logic[1:0] in_high;
    logic[1:0] in_mid;
    logic[1:0] in_low;
    logic[1:0] out_high;
    logic[1:0] out_mid;
    logic[1:0] out_low;

    assign in_high[0] = word_i[2];
    assign in_high[1] = out_mid[1];
    assign in_mid[0]  = word_i[0];
    assign in_mid[1]  = word_i[1];
    assign in_low[0]  = out_mid[0];
    assign in_low[1]  = out_high[0];
    assign out[0]     = out_low[0];
    assign out[1]     = out_low[1];
    assign out[2]     = out_high[1];

    benes_network #(
        .N(2),
        .CNT(1)
    ) benes_high_net(
        .clk(clk),
        .reset(reset),
        .word_i(in_high),
        .control(control[2]),
        .word_o(out_high)
    );
    benes_network #(
        .N(2),
        .CNT(1)
    ) benes_mid_net(
        .clk(clk),
        .reset(reset),
        .word_i(in_mid),
        .control(control[1]),
        .word_o(out_mid)
    );
    benes_network #(
        .N(2),
        .CNT(1)
    ) benes_low_net(
        .clk(clk),
        .reset(reset),
        .word_i(in_low),
        .control(control[0]),
        .word_o(out_low)
    );

    
endmodule
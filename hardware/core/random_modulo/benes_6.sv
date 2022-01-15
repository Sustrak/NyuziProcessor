`include "defines.svh"

import defines::*;

//
//This module implements the Benes Network algorithm
//used by the Random Modulo in the L1 caches.
//

module benes_network_6
    #(parameter N = 6,
    parameter   CNT = 12)
    (input                clk,
    input                 reset,

    input logic[N-1:0]    word_i,
    input logic[CNT-1:0]  control,   
    output logic[N-1:0]   word_o);

    //Actual code
    `define N_H (N/2)

    genvar i;
    generate

        logic[N-1:0] in_after_entry;
        logic[N-1:0] out_after_exit;
        logic[N-1:0] control_own;
        logic[`N_H-1:0] in_high;
        logic[`N_H-1:0] in_low;
        logic[`N_H-1:0] out_high;
        logic[`N_H-1:0] out_low;
        logic[`N_H-1:0] cnt_high;
        logic[`N_H-1:0] cnt_low;
        assign control_own = control[(CNT-1):(CNT-N)];
        for(i = 0; i < N; i+=2)
        begin
            assign in_after_entry[i]   = control_own[i] ? word_i[i+1] : word_i[i];
            assign in_after_entry[i+1] = control_own[i] ? word_i[i] : word_i[i+1];
            assign in_high[i/2] = in_after_entry[i+1];
            assign in_low[i/2]  = in_after_entry[i];
            assign out_after_exit[i]   = out_low[i/2];
            assign out_after_exit[i+1] = out_high[i/2];
            assign word_o[i]   = control_own[i+1] ? out_after_exit[i+1] : out_after_exit[i];
            assign word_o[i+1] = control_own[i+1] ? out_after_exit[i] : out_after_exit[i+1];
        end
        assign in_high = in_after_entry[N-1:`N_H];
        assign in_low  = in_after_entry[`N_H-1:0];
        assign out_after_exit[N-1:`N_H] = out_high;
        assign out_after_exit[`N_H-1:0] = out_low;
        assign cnt_high = control[`CNT_S-1:`CNT_H];
        assign cnt_low = control[`CNT_H-1:0];

        benes_network_3 #(
        ) benes_high_half_net(
            .clk(clk),
            .reset(reset),
            .word_i(in_high),
            .control(cnt_high),
            .word_o(out_high)
        );
        benes_network_3 #(
        ) benes_low_half_net(
            .clk(clk),
            .reset(reset),
            .word_i(in_low),
            .control(cnt_low),
            .word_o(out_low)
        );
    endgenerate
    
endmodule
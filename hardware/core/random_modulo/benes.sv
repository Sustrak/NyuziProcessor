`include "defines.svh"

import defines::*;

//
//This module implements the Benes Network algorithm
//used by the Random Modulo in the L1 caches.
//

module benes_network
    #(parameter N = 8,
    parameter   CNT = 20)
    (input                clk,
    input                 reset,

    input logic[N-1:0]    word_i,
    input logic[CNT-1:0]  control,   
    output logic[N-1:0]   word_o);

    //Actual code
    genvar i;
    generate
        if(N==1) begin
            assign word_o[0] = word_i[0];
        end
        else if(N==2) begin
            assign word_o[0] = word_i[control[0]];
            assign word_o[1] = word_i[~control[0]];
        end
        else begin
            `define N_H (N/2)
            `define CNT_H ((CNT - N)/2)
            `define CNT_S (CNT - N)

            logic[N-1:0] in_after_entry;
            logic[N-1:0] out_after_exit;
            logic[N-1:0] control_own;
            logic[`N_H-1:0] in_high;
            logic[`N_H-1:0] in_low;
            logic[`N_H-1:0] out_high;
            logic[`N_H-1:0] out_low;
            logic[`CNT_H-1:0] cnt_high;
            logic[`CNT_H-1:0] cnt_low;
            assign control_own = control[CNT-1:`CNT_S];
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

            benes_network #(
                .N(`N_H),
                .CNT(`CNT_H)
            ) benes_high_half_net(
                .clk(clk),
                .reset(reset),
                .word_i(in_high),
                .control(cnt_high),
                .word_o(out_high)
            );
            benes_network #(
                .N(`N_H),
                .CNT(`CNT_H)
            ) benes_low_half_net(
                .clk(clk),
                .reset(reset),
                .word_i(in_low),
                .control(cnt_low),
                .word_o(out_low)
            );
        end
    endgenerate
    
endmodule
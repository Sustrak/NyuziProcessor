`include "defines.svh"

import defines::*;

//
//This module implements the Pseudo-Random Number Generator (PRNG)
//used by the Random Modulo in the L1 caches.
//

module prng
    #(parameter SEED = 168'hef4a66be741ca34e9143bfa4c10c4b14af2bb26021,
    parameter NBITS = 168,
    parameter NNUM = 16)
    (input                   clk,
    input                    reset,

    output logic[NNUM-1:0]   rand_o);

    //Actual code
    logic[NBITS-1:0] lsfr;
    logic[NNUM-1:0][3:0] xnor_i;
    logic[NNUM-1:0] xnor_o;

    assign rand_o = xnor_o;

    genvar i;
    generate
        for(i=0; i < NNUM; i++)
        begin
            assign xnor_i[i][0] = lsfr[NBITS - NNUM + i];
            assign xnor_i[i][1] = lsfr[NBITS - NNUM + i - 2];
            assign xnor_i[i][2] = lsfr[NBITS - NNUM + i - 15];
            assign xnor_i[i][3] = lsfr[NBITS - NNUM + i - 17];
            assign xnor_o[i]    = ~(xnor_i[i][0] ^ xnor_i[i][1] ^ xnor_i[i][2] ^ xnor_i[i][3]);
        end
    endgenerate
    
    always_ff @(posedge clk, posedge reset) 
    begin 
        if(reset)
            lsfr <= SEED;
        else begin
            for(int j = NBITS-1; j >= NNUM; j--)
                lsfr[j] <= lsfr[j-1];
            for(int j = NNUM-1; j >= 0; j--)
                lsfr[j] <= xnor_o[j];
        end    
    end
    
endmodule

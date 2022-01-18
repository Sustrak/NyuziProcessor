`include "defines.svh"

import defines::*;

//
//

module random_placement
    #(parameter INDX_BITS = 6,
    parameter   ADDR_BITS = 24,
    parameter   CONT_BITS = 12)
    (input                      clk,
    input                       reset,

    input logic                 reseed,
    input logic[ADDR_BITS-1:0]  raddr,
    input logic[ADDR_BITS-1:0]  waddr,   
    output logic[INDX_BITS-1:0] rindex,
    output logic[INDX_BITS-1:0] windex);

    //Actual code
    logic[CONT_BITS-1:0] prng_o; //Seed from the PRNG module
    logic[CONT_BITS-1:0] seed; //Current seed
    logic[CONT_BITS-1:0] cont_w;
    logic[CONT_BITS-1:0] cont_r;

    assign cont_w = waddr[INDX_BITS + CONT_BITS - 1 : INDX_BITS] ^ seed;
    assign cont_r = raddr[INDX_BITS + CONT_BITS - 1 : INDX_BITS] ^ seed;

    prng #(
        .NNUM(CONT_BITS)
    ) seed_gen(
        .clk(clk),
        .reset(reset),
        .rand_o(prng_o)
    );

    benes_network_6 benes_write(
        .clk(clk),
        .reset(reset),
        .word_i(waddr[INDX_BITS-1:0]),
        .control(cont_w),
        .word_o(windex)
    );
    benes_network_6 benes_read(
        .clk(clk),
        .reset(reset),
        .word_i(raddr[INDX_BITS-1:0]),
        .control(cont_r),
        .word_o(rindex)
    );

    always_ff @(posedge clk, posedge reset) 
    begin
        if(reset)
            seed <= prng_o;
        //else if(reseed)
        //    seed <= prng_o;        
    end

endmodule

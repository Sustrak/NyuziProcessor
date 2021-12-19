//
// Copyright 2011-2015 Jeff Bush
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

`include "defines.svh"

import defines::*;

//
// Block SRAM with 1 read port and 1 write port.
// Reads and writes are performed synchronously. The read value appears
// on the next clock edge after the address and read_en are asserted
// If read_en is not asserted, the value of read_data is undefined during
// the next cycle. The READ_DURING_WRITE parameter determines what happens
// if a read and a write are performed to the same address in the same cycle:
//  - "NEW_DATA" this will return the newly written data ("read-after-write").
//  - "DONT_CARE" The results are undefined. This can be used to improve clock
//    speed.
// This does not clear memory contents on reset.
//

// ECC:
//   Implement a bit parity on the data array. If the bit parity don't check a error flag is raised.
//   For each write the parity bit is re-computed again

module sram_1r1w_pb
    #(parameter DATA_WIDTH = 32,
    parameter SIZE = 1024,
    parameter READ_DURING_WRITE = "NEW_DATA",
    parameter ADDR_WIDTH = $clog2(SIZE))

    (input                         clk,
    input                          read_en,
    input [ADDR_WIDTH - 1:0]       read_addr,
    output logic[DATA_WIDTH - 1:0] read_data,
    input                          write_en,
    input [ADDR_WIDTH - 1:0]       write_addr,
    input [DATA_WIDTH - 1:0]       write_data,
    output logic                   ecc_pb_error);

    // Simulation
    logic[DATA_WIDTH - 1:0] data[SIZE];
    // Parity bit array
    logic [SIZE-1:0] data_pb;

    logic [DATA_WIDTH:0] data_w_pb;
    logic [DATA_WIDTH-1:0] rd_data_wo_pb;

    logic parity_bit;

    logic pb_error;

    parity_encoder #(.DATA_WIDTH(DATA_WIDTH)) pb_encoder (
        .word_to_code(write_data), 
        .coded_word(data_w_pb));

    parity_checker #(.DATA_WIDTH(DATA_WIDTH)) pb_checker (
        .coded_word({data[read_addr],parity_bit}),
        .data(rd_data_wo_pb),
        .error(pb_error));

    assign ecc_pb_error = pb_error & read_en;
    //assign ecc_pb_error = (read_addr == 8'h80) ? 1'b1 : 1'b0;

    //always_comb
    //begin
    //    parity_bit = data_pb[read_addr];
    //    if (1'($random())) begin
    //        parity_bit = !data_pb[read_addr];
    //    end
    //end
    assign parity_bit = data_pb[read_addr];

    // Note: use always here instead of always_ff so Modelsim will allow
    // initializing the array in the initial block (see below).
    always @(posedge clk)
    begin
        if (write_en) begin
            data[write_addr] <= data_w_pb[DATA_WIDTH:1]; 
            data_pb[write_addr] <= data_w_pb[0];
        end

        if (write_addr == read_addr && write_en && read_en)
        begin
            if (READ_DURING_WRITE == "NEW_DATA")
                read_data <= write_data;    // Bypass
            else
                read_data <= DATA_WIDTH'($random()); // ensure it is really "don't care"
        end
        else if (read_en)
            read_data <= rd_data_wo_pb;
        else
            read_data <= DATA_WIDTH'($random());
    end

    initial
    begin
        for (int i = 0; i < SIZE; i++) begin
            data[i] = '0;
            data_pb[i] = 0;
        end

        if ($test$plusargs("dumpmems") != 0)
            $display("sram1r1w %d %d", DATA_WIDTH, SIZE);
    end
endmodule

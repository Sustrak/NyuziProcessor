`include "defines.svh"

import defines::*;

module voting_sram_2r1w_tb();
    logic clk, reset;
  
    localparam SIZE = 32;
    localparam ADDR_WIDTH = $clog2(SIZE);
    localparam DATA_WIDTH = 32;

    logic read1_en;
    logic [ADDR_WIDTH - 1:0] read1_addr;
    logic [DATA_WIDTH - 1:0] read1_data;
    logic read2_en;
    logic [ADDR_WIDTH - 1:0] read2_addr;
    logic [DATA_WIDTH - 1:0] read2_data;
    logic write_en;
    logic [ADDR_WIDTH - 1:0] write_addr;
    logic [DATA_WIDTH - 1:0] write_data;

  	initial begin
  		$dumpfile("dump.vcd");
  		$dumpvars;
        
	end  

    initial begin
        clk = 0;
      	read1_en = 0;
      	read2_en = 0;
      	write_en = 0;
    end

    initial begin
        forever begin
            #10 clk = ~clk;
        end
    end

    voting_sram_2r1w #(
        .DATA_WIDTH($bits(scalar_t)),
        .SIZE(SIZE)
    ) dut
    (
        .clk        (clk),
        .read1_en   (read1_en),
        .read1_addr (read1_addr),
        .read1_data (read1_data),
        .read2_en   (read2_en),
        .read2_addr (read2_addr),
        .read2_data (read2_data),
        .write_en   (write_en),
        .write_addr (write_addr),
        .write_data (write_data)
    );

    initial begin
        for(int i = 0; i < 100; i++) begin
          if (1'($random())) write_reg(DATA_WIDTH'($random()), ADDR_WIDTH'($random()));
          else read_reg(5'($random()), 5'($random()), $urandom_range(1, 3));
        end
      $finish;
    end

  task write_reg(logic [DATA_WIDTH-1:0] data, logic [ADDR_WIDTH-1:0] addr);
        write_en = 1'b1;
        write_addr = addr;
        write_data = data;
        $display("Writing %h at %d", data, addr);
        @(posedge clk);
        write_en = 1'b0;
        write_addr = '0;
        write_data = '0;
    endtask

    task read_reg(logic [4:0] addr1, logic [4:0] addr2, int port);
        if (port == 1) begin
            read1_en = 1'b1;
            read1_addr = addr1;
            $display("Reading data from port 1, addr: %d data: %h", addr1, read1_data);
        end 
        else if (port == 2) begin
            read2_en = 1'b1;
            read2_addr = addr2;
            $display("Reading data from port 2, addr: %d data: %h", addr2, read2_data);
        end
        else begin
            read1_en = 1'b1;
            read1_addr = addr1;
            read2_en = 1'b1;
            read2_addr = addr2;
            $display("Reading data from port 1, addr: %d data: %h", addr1, read1_data);
            $display("Reading data from port 2, addr: %d data: %h", addr2, read2_data);
        end
        detect_mismatch(); 
        @(posedge clk);
        //detect_mismatch();
        read1_en = 1'b0;
        read2_en = 1'b0;
        read1_addr = '0;
        read2_addr = '0;
    endtask

    function void detect_mismatch();
        if (dut.voting_mismatch[0]) begin
          $display("Detected in bank %d addr %0d a data mismatch", dut.voting_mismatch_reg[0], dut.voting_mismatch_addr[0]);
        end
        if (dut.voting_mismatch[1]) begin
          $display("Detected in bank %d addr %0d a data mismatch", dut.voting_mismatch_reg[1], dut.voting_mismatch_addr[1]);
        end
    endfunction
  
  //initial begin
  //      fork
  //          begin
  //              forever begin
  //                  @(posedge clk);
  //                  if ($urandom_range(0, 10) == 1'd0) begin
  //                      automatic int bank = $urandom_range(0,2);
  //                      automatic int addr = ADDR_WIDTH'($urandom());
  //                      automatic logic [DATA_WIDTH-1:0] random_data = DATA_WIDTH'($random());
  //                    $display("ECC (RF): Injecting error in bank %d addr %d, new random data is %d", bank, addr, random_data);
  //                    dut.data[bank][addr] = random_data;
  //                  end
  //              end
  //          end
  //      join_none
  //  end

endmodule

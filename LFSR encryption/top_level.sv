// starter code for Lab 4
// CSE140L
module top_level (
  input        clk, 
               init,
  output logic done);

// dat_mem interface
// you will need this to talk to the data memory
logic        write_en;        // data memory write enable        
logic[8-1:0] raddr,           // read address pointer
             waddr;           // write address pointer
logic[8-1:0] data_in;         // to dat_mem 
wire [8-1:0] data_out;        // from dat_mem
// LFSR control input and data output
logic         LFSR_en;         // 1: advance LFSR; 0: hold		
// taps, start, pre_len are constants loaded from dat_mem [61:63]
logic[   5:0] taps,            // LFSR feedback pattern temp register
              start;           // LFSR initial state temp register
logic[   7:0] pre_len;         // preamble (_____) length           
logic         taps_en,         // 1: load taps register; 0: hold
              start_en,        //   same for start temp register
              prelen_en;       //   same for preamble length temp
logic         load_LFSR;       // copy taps and start into LFSR
wire [   5:0] LFSR;            // LFSR current value            
logic[   7:0] ct_inc;          // prog count step (default = +1)
// instantiate the data memory 
dat_mem dm1(.clk, .write_en, .raddr, .waddr,
            .data_in, .data_out);

// instantiate the LFSR core
// need one for Lab 4; may want 6 for Lab 5
lfsr6 l6(.clk, .en(LFSR_en), .init(load_LFSR),
         .taps, .start, .state(LFSR));

logic[7:0] ct;                  // your program counter
// this can act as a program counter
always @(posedge clk)
  if(init)
    ct <= 0;
  else 
	ct <= ct + ct_inc;     // default: next_ct = ct+1

// load control registers from dat_mem 
always @(posedge clk)
  if(prelen_en)
    pre_len <= data_out;      // copy from data_mem[61] to pre_len reg.
  else if(taps_en)
    taps    <= data_out;      // copy from data_mem[62] to taps reg.
  else if(start_en)
    start   <= data_out;      // copy from data_mem[63] to start reg.  

// control decode logic (does work of instr. mem and control decode)
always_comb begin
// list defaults here; case needs list only exceptions
  write_en  = 'b0;         // data memory write enable        
  LFSR_en   = 'b0;         // 1: advance LFSR; 0: hold		
// enables to load control constants read from dat_mem[61:63] 
  prelen_en = 'b0;         // 1: load pre_len temp register; 0: hold
  taps_en   = 'b0;         // 1: load taps temp register; 0: hold ]]]]]]]]]]]]]]]]]]]
  start_en  = 'b0;         // 1: load start temp register; 0: hold
  load_LFSR = 'b0;         // copy taps and start into LFSR
// PC normally advances by 1
// override to go back in a subroutine or forward/back in a branch 
  ct_inc    = 'b1;         // PC normally advances by 1
	raddr=0;
	waddr=0;
	data_in=0;
  case(ct)
    0,1: begin   
         raddr     = 'd0;         // memory read address pointer
   		   waddr     = 'd64;    	// memory write address pointer
				 write_en  = 'b0;
         end       // no op to wait for things to settle from init
// first tasks to be done:
// 1) raddr = 61, prelen_en = 1
//    pre_len <= data_out  
// 2) raddr = 62, taps_en = 1
//    taps <= data_out
// 3) raddr = 63, start_en = 1
//    start <= data_out
    2:   begin             // load pre_len temp register
           raddr      = 'd61;
           waddr      = 'd64;         // memory write address pointer
           prelen_en  = 'b1;
					 write_en  = 'b0;
         end
    3:   begin             // load taps temp reg
           raddr      = 'd62;   
           waddr      = 'd64;
           taps_en    = 'b1;
					 write_en  = 'b0;
         end               // load LFSR start temp reg
    4:   begin
           raddr      = 'd63;
					 waddr      = 'd64;
           start_en   = 'b1;
					 write_en  = 'b0;
         end
	5:   begin
	       raddr      = 'd0;
		   waddr      =	'd64;
		   load_LFSR  = 'b1;   // copy taps and start temps into LFSR
			 write_en  = 'b0;
		 end      
  endcase
	
 if(ct>=6&&ct<=(6+pre_len-1)) begin
		
    waddr    = ct+58; //58+6=64
		data_in  = {2'b00,LFSR}^8'h5F; 
	  write_en = 'b1;
	  LFSR_en  = 'b1;
  end
  else if(ct>=(6+pre_len) && ct <= (6+pre_len)+(64-pre_len)) begin
		
    raddr     = ct-(6+pre_len)+1; //load from dat_mem[1]
		waddr     = ct+58;
		data_in   = data_out^{2'b00,LFSR};
    write_en  = 'b1;
		LFSR_en   = 'b1;
  end 
	
end 


/* My done flag goes high once every 64 clock cycles
   Yours should go high at the completion of your encryption operation.
   This may be more or fewer clock cycles than mine. 
   Test bench waits for a done flag, so generate one at some time.
*/
  assign done = (ct == (6+pre_len)+(64-pre_len)+1);

endmodule
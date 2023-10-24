// ECE260C -- lab 5 alternative DUT
// applies done flag when cycle_ct = 255
module top_level_5b(
  input          clk, init, 
  output logic   done);
	
// memory interface
  logic          wr_en;
  logic    [7:0] raddr, 
                 waddr,
                 data_in;
	logic[7:0] ct_inc;
  logic[7:0] ct;
  logic[7:0] regg;
  logic    [7:0] data_out;       
	 
  logic load_LFSR,
        LFSR_en;
  logic[5:0] LFSR_ptrn[6];
  assign LFSR_ptrn[0] = 6'h21;
  assign LFSR_ptrn[1] = 6'h2D;
  assign LFSR_ptrn[2] = 6'h30;
  assign LFSR_ptrn[3] = 6'h33;
  assign LFSR_ptrn[4] = 6'h36;
  assign LFSR_ptrn[5] = 6'h39;
	logic[5:0] start;                  // LFSR starting state
  logic[5:0] LFSR_state[6];
  logic[5:0] match;					 // got a match for LFSR (one hot)
  logic[2:0] foundit;                // binary index equiv. of match
  int i;
	
  logic[5:0] LFSR[64];
  int        fronted_num;
	logic      find_score;	
  //logic[7:0] foundit;
  logic      write_en;
  logic      start_en;
  logic      LFSR6_en;
  logic      youlika;
  logic      write_1;
  logic      write_2;

  dat_mem dm1(.clk,.write_en,.raddr,.waddr,
       .data_in,.data_out);    
				
// 6 parallel LFSRs -- fill in the missing connections
  lfsr6 l0(.clk() , 
         .en   (LFSR_en)  ,            // 1: advance LFSR on rising clk
         .init (load_LFSR),	            // 1: initialize LFSR
         .taps (6'h21)     ,    // tap pattern 0
         .start() ,	            // starting state for LFSR
         .state(LFSR_state[0]));		   // LFSR state = LFSR output 

  lfsr6 l1(.clk, .en(LFSR_en), .init(load_LFSR), .taps(LFSR_ptrn[1]), .start, .state(LFSR_state[1]));
  lfsr6 l2(.clk, .en(LFSR_en), .init(load_LFSR), .taps(LFSR_ptrn[2]), .start, .state(LFSR_state[2]));
  lfsr6 l3(.clk, .en(LFSR_en), .init(load_LFSR), .taps(LFSR_ptrn[3]), .start, .state(LFSR_state[3]));
  lfsr6 l4(.clk, .en(LFSR_en), .init(load_LFSR), .taps(LFSR_ptrn[4]), .start, .state(LFSR_state[4]));
  lfsr6 l5(.clk, .en(LFSR_en), .init(load_LFSR), .taps(LFSR_ptrn[5]), .start, .state(LFSR_state[5]));

  always_comb begin
  done='b0;
  write_en='b0;
	youlika='b0;
  write_1='b0;
  raddr='b0;
	start_en= 'b0;
  LFSR6_en='b0; 
	find_score='b0;
  write_2='b0;	
  waddr='b0;
	LFSR_en='b0;
	ct_inc='b1;
  data_in='b0;
  load_LFSR= 'b0;

  case(ct)
    0,1:begin   
		end
		
    2:begin
      raddr='d64;
      start_en='b1;
    end
		
	 3:begin
	     load_LFSR='b1;
		end
		
	 4:begin
		ct_inc='b0;
		LFSR6_en='b1;
		raddr=regg+64;
   end
	 
	 5,6,7,8,9,10:begin
		LFSR_en='b1;
	 end

	 11:begin
	  youlika='b1;
	 end
			
	 12:  begin
		write_1='b1;
		ct_inc='b0;
		raddr=regg+'d64-'d7;
		waddr=regg-'d7;
		write_en='b1;
		data_in=data_out^{2'b0,LFSR[regg-7]};
	 end
	 
	 14:  begin
		find_score='b1;
		ct_inc='b0;
		raddr=regg;
	 end
	 
	 16:  begin
		write_2='b1;
		ct_inc='b0;
		raddr=regg+fronted_num;
		waddr=regg;
		write_en='b1;
		data_in=data_out;
	 end
	 
	 17:  begin
	  done='b1;
	 end
	 
	 default: begin 
	 end
	 
  endcase
end 

  always @(posedge clk) begin  :clock_loop
    if(init) begin
	  ct<='b0;
	  regg<='b0;
		end
	 else begin
		ct<=ct + ct_inc;
	 end
	 
	 if(start_en) begin
    start<=6'h1f^data_out[5:0];
	 end
	 
	 if(LFSR6_en) begin
	  LFSR[regg] = data_out[5:0]^6'h1f;
		regg<=regg+'b1;
		if(regg==6) begin
		  regg<=7;
		  ct<=ct+'b1;
		end
	 end
	 
	 if(youlika) begin
		  for(int mm=0;mm<6;mm++) begin :ureka_loop  
		    if(LFSR_state[mm]==LFSR[6]) begin
					foundit=mm;
					match=LFSR_state[mm];
        end
		  end :ureka_loop
		  for(int jm=0;jm<63;jm++) begin
				LFSR[jm+1]=(LFSR[jm]<<1)+(^(LFSR[jm]&LFSR_ptrn[foundit]));
			end
	 end

    if(write_1) begin
			regg<=regg+'b1;
			if(regg==64-8 ) begin
				regg<=0;
				ct<=ct+'b1;
			end
		end	
	 
    if(find_score) begin
			if( data_out == 8'h5f ) begin
				regg<=regg + 'b1;
			end
			else begin
				fronted_num<=regg;
				regg<='d0;
				ct<=ct+'b1;
			end
			if( regg=='d64 ) begin
				regg<='d0;
				ct<=ct+'b1;
			end   
		end

	 if(write_2) begin
		regg<=regg+'b1;
		if(regg=='d63) begin
		  ct<=ct+'b1;
		end			
	 end	 
         
  end  :clock_loop

endmodule
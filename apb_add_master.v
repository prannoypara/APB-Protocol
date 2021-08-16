
module apb_add_master (
  input pclk,
  input preset_n, 	// Active low reset
  input [1:0]add_i,		// 2'b00 - NOP, 2'b01 - READ, 2'b11 - WRITE indicates we want to perform a transaction.
  input  [31:0]prdata_i, 
  input pready_i,
  
  output psel_o,
  output penable_o, //when penable_o =1 it means that transaction is enabled.
  output [31:0]paddr_o,
  output pwrite_o,
  output [31:0] pwdata_o
  
  
);
  
  parameter ST_IDLE = 2'b00, ST_SETUP = 2'b01, ST_ACCESS = 2'b10;
  
  reg[1:0] state_q; 		// Current state
  reg[1:0] nxt_state;	// Next state
  
  wire apb_state_setup;
  wire apb_state_access;
  
  reg nxt_pwrite;
  reg pwrite_q;
  
  reg [31:0] nxt_rdata;
  reg [31:0] rdata_q;
  
  always @(posedge pclk or negedge preset_n)
    if (~preset_n)
      state_q <= ST_IDLE;
  	else
      state_q <= nxt_state; //current state must be next state.
  
  always @* begin
    nxt_pwrite = pwrite_q; 
	nxt_rdata = rdata_q; 
	case (state_q)
      ST_IDLE:
          if (add_i[0]) begin 
		      nxt_state = ST_SETUP;
              nxt_pwrite = add_i[1]; 
              end  
		 else 
          nxt_state = ST_IDLE;
        
      ST_SETUP: nxt_state = ST_ACCESS;
      ST_ACCESS:
         if (pready_i) 
		  begin 
		   if (~pwrite_q) 
		    nxt_rdata = prdata_i;
            nxt_state = ST_IDLE; 
		  end 
		 else
           nxt_state = ST_ACCESS; 
      default: nxt_state = ST_IDLE;
    endcase
  end
  
  assign apb_state_access = (state_q == ST_ACCESS); //these signals tells in which state we are in.
  assign apb_state_setup = (state_q == ST_SETUP);
  
  assign psel_o = apb_state_setup | apb_state_access; //psel_o must be ON through out setup and access states.
  assign penable_o = apb_state_access; //penable_o must be on only if we are in access state.
  
  // APB Address
  assign paddr_o = {32{apb_state_access}} & 32'hA000; //addresss must be stable when ur in access state.
  
  // APB PWRITE control signal
  always @(posedge pclk or negedge preset_n)
    if (~preset_n)
      pwrite_q <= 1'b0; //means read  
  	else
      pwrite_q <= nxt_pwrite; //we store from add_i[1] it into flop.
  
  assign pwrite_o = pwrite_q; 
  assign pwdata_o = {32{apb_state_access}} & (rdata_q + 32'h1); 
  
  // APB PREAD control signal
  always @(posedge pclk or negedge preset_n)
    if (~preset_n)
      rdata_q <= 32'h0; //if reset we are making the data to all zeros.
  	else
      rdata_q <= nxt_rdata; 
endmodule
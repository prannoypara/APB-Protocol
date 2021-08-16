
`define CLK @(posedge pclk)

module apb_slave_tb ();
  
	reg	pclk;
	reg 	    preset_n; 	// Active low reset
    reg [31:0]	prdata_i;
 	reg			pready_i;
    reg[1:0]    add_i;		// 2'b00 - NOP, 2'b01 - READ, 2'b11 - WRITE
  
	wire 			psel_o;
	wire 			penable_o;
  	wire [31:0]	    paddr_o;
	wire			pwrite_o;
  	wire [31:0] 	pwdata_o;
  	
  // Implement clock
  always begin
    pclk = 1'b0;
    #5;
    pclk = 1'b1;
    #5;
  end
  
  // Instantiate the RTL
  apb_add_master APB_MASTER (.*);
  
  // Drive stimulus
  initial begin
    preset_n = 1'b0; //time= 0
    add_i = 2'b00;
    repeat (2) `CLK; // time=15
    preset_n = 1'b1;
    repeat (2) `CLK; //at the end of this time = 35;
    
    // Initiate a read transaction
    add_i = 2'b01; //ur add_i is 1 here i.e., u initiate
    `CLK; //time =45
    add_i = 2'b00;
    repeat (4) `CLK; //at time =85 posedge of the clk occurs.
    
    // Initiate a write transaction
    add_i = 2'b11;
    `CLK; //time =95;
    add_i = 2'b00;
    repeat (4) `CLK; //time =135
    $finish();
  end
  
  // APB Slave
  always @(posedge pclk or negedge preset_n) 
  begin
    if (~preset_n)
      pready_i <= 1'b0; //it will be till 15ns 
    else 
	begin
       if (psel_o && penable_o)  //psel will be high at 45ns , Penable at 55ns
	    begin
          pready_i <= 1'b1; //hence Pready will be 1 at 65ns.
          prdata_i <= $random%32'h20;
        end 
	   else 
	    begin
          pready_i <= 1'b0; //till 65ns Pready will be 0
          prdata_i <= $random%32'hFF; //till then prdata will be some random values.
       end
    end
  end 
endmodule


  // VCD Dump
  //initial begin
   // $dumpfile("apb_master.vcd");
    //$dumpvars(2, apb_slave_tb);
  //end

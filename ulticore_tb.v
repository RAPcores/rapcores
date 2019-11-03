module testbench();

  reg clk;
  reg enc1a;
  reg enc1b;
  reg enc2a;
  reg enc2b;
  reg enc3a;
  reg enc3b;
  reg enc4a;
  reg enc4b;
  reg enc5a;
  reg enc5b;
  reg enc6a;
  reg enc6b;
  reg enc7a;
  reg enc7b;
  reg enc8a;
  reg enc8b;
  wire [7:0]led;
  reg faultn;
  wire [31:0] count1, count2, count3, count4, count5, count6, count7, count8;
//  wire resetn;
//  wire resetn_tb;
  reg [7:0] resetn_tb_counter = 0;
  reg [7:0] fault;
  reg [20:0] cnt;

/*
// Reset
  assign resetn_tb = &resetn_tb_counter;

  always @(posedge clk) begin
    if (!resetn) resetn_counter <= resetn_counter +1;
  end
*/

// Clock stimulation
  always #5 clk = (clk === 1'b0);

  initial begin
    $dumpfile("testbench.vcd");
    $dumpvars(0, testbench);

    repeat (10) begin
      repeat (256) @(posedge clk);
      $display("+256 cycles");
    end
    $finish;
  end

// Debug output

  always @(fault) begin
    #1 $display("%b", fault);
  end

  always @(led) begin
    #1 $display("%b", led);
  end

// Reset TB timer
  assign resetn_tb = &resetn_tb_counter;

  always @(posedge clk) begin
    if (!resetn_tb) resetn_tb_counter <= resetn_tb_counter +1;
  end


// Encoder Stimulation

  reg [3:0] enccntA = 0;
  reg [3:0] enccntB = 4;

  always @(posedge clk) begin
    if(!resetn_tb) begin
      cnt <= 0;
      fault[7:0] <= 'b11111111;
    end
    faultn <= &fault;
    cnt <= cnt + 1;
    if (cnt <= 20'h90) begin
      enccntA <= enccntA + 1;
      enc1a <= enccntA[3];
      enccntB <= enccntB - 1;
      enc1b <= enccntB[3];
      enc2a <= enc1b;
      enc2b <= enc1a;
      enc3a <= enc1a;
      enc3b <= enc1b;
      enc4a <= enc1b;
      enc4b <= enc1a;
      enc5a <= enc1a;
      enc5b <= enc1b;
      enc6a <= enc1b;
      enc6b <= enc1a;
      enc7a <= enc1a;
      enc7b <= enc1b;
      enc8a <= enc1b;
      enc8b <= enc1a;
    end
    else begin
      cnt <=0;
      enc2a <= ~enc2a;  //Inject fault in encoder 2
      enc2b <= ~enc2b;
      enc7a <= ~enc7a;
      enc7b <= ~enc7b;
    end

  end


// UUT

  ulticore uut (
    .clk  (clk  ),
    .enc1a (enc1a ),
    .enc1b (enc1b ),
    .enc2a (enc2a ),
    .enc2b (enc2b ),
    .enc3a (enc3a ),
    .enc3b (enc3b ),
    .enc4a (enc4a ),
    .enc4b (enc4b ),
    .enc5a (enc5a ),
    .enc5b (enc5b ),
    .enc6a (enc6a ),
    .enc6b (enc6b ),
    .enc7a (enc7a ),
    .enc7b (enc7b ),
    .enc8a (enc8a ),
    .enc8b (enc8b ),
    .LED0 (led[0] ),
    .LED1 (led[1] ),
    .LED2 (led[2] ),
    .LED3 (led[3] ),
    .LED4 (led[4] ),
    .LED5 (led[5] ),
    .LED6 (led[6] ),
    .LED7 (led[7] )
  );
endmodule

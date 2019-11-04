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
  reg step1;
  reg step2;
  reg step3;
  reg step4;
  reg step5;
  reg step6;
  reg step7;
  reg step8;
  reg dir1;
  reg dir2;
  reg dir3;
  reg dir4;
  reg dir5;
  reg dir6;
  reg dir7;
  reg dir8;
  wire [7:0]led;
  reg faultn;
//  wire [31:0] enc_count1, enc_count2, enc_count3, enc_count4, enc_count5, enc_count6, enc_count7, enc_count8;
  reg [3:0] resetn_tb_counter = 0;
  reg [7:0] fault;
  reg [20:0] cnt = 0;
  reg [7:0] invert_dir = 0;
  reg [7:0] step_active_high = 256;

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
    else begin
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
        step1 <= enccntA[3];
        step2 <= enccntA[3];
        step3 <= enccntA[3];
        step4 <= enccntA[3];
        step5 <= enccntA[3];
        step6 <= enccntA[3];
        step7 <= enccntA[3];
        step8 <= enccntA[3];
        dir1 <= 0;
        dir2 <= 0;
        dir3 <= 0;
        dir4 <= 0;
        dir5 <= 0;
        dir6 <= 0;
        dir7 <= 0;
        dir8 <= 0;
      end
      else begin
//        cnt <=0;
        enccntA <= enccntA + 1;
        enc1a <= enccntA[3];
        enccntB <= enccntB - 1;
        enc1b <= enccntB[3];
        enc2a <= ~enc2a;  //Inject fault in encoder 2
        enc2b <= ~enc2b;
        enc7a <= ~enc7a;
        enc7b <= ~enc7b;
        step1 <= enccntA[3]; //Step opposite direction
        step2 <= enccntA[3];
        step3 <= enccntA[3];
        step4 <= enccntA[3];
        step5 <= enccntA[3];
        step6 <= enccntA[3];
        step7 <= enccntA[3];
        step8 <= enccntA[3];
        dir1 <= 1;
        dir2 <= 1;
        dir3 <= 1;
        dir4 <= 1;
        dir5 <= 1;
        dir6 <= 1;
        dir7 <= 1;
        dir8 <= 1;
      end
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
    .LED7 (led[7] ),
    .invert_dir (0),
    .step_active_high (256),
    .step1 (step1),
    .step2 (step2),
    .step3 (step3),
    .step4 (step4),
    .step5 (step5),
    .step6 (step6),
    .step7 (step7),
    .step8 (step8),
    .dir1 (dir1),
    .dir2 (dir2),
    .dir3 (dir3),
    .dir4 (dir4),
    .dir5 (dir5),
    .dir6 (dir6),
    .dir7 (dir7),
    .dir8 (dir8)
  );
endmodule

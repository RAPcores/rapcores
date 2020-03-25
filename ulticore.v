/*
 *
 *  UltiCores -- IP Cores for Mechatronic Control Systems
 *
 *  Copyright (C) 2019 UltiMachine <info@ultimachine.com>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

`timescale 1ns/100ps

module soc(
  input clk, 
  input enc1a,
  input enc1b,
  input enc2a,
  input enc2b,
  input step1,
  input dir1,
  output LED0,
  output LED1,
  output LED2,
  output LED3,
  output LED4,
  output LED5,
  output LED6,
  output LED7,
  output faultn,
  input SCK,
  input SSEL,
  input MOSI,
  output MISO,
  //input A0_P,
  //output A0_PWM
  output POSITION_INTERRUPT,
  );

  
  wire signed [31:0] pos_count1;
  
//  reg enc1a, enc1b, enc2a, enc2b;
  wire signed [31:0] count1, count2;
//  reg resetn;
  wire resetn;
  reg [7:0] resetn_counter = 0;
  wire faultn;
  wire [7:0] fault;
  
  wire byte_received;  // high when a byte has been received
  wire [7:0] byte_data_received;
  wire [31:0] packet_received;
  
  reg [31:0] spi_send_data;
  
  wire [7:0] adc_result;
  wire sample_rdy;
  
  wire [31:0] response_data;
  
  reg [7:1] step_multiplier;
  reg [7:1] quad_multiplier;
  
  reg [7:0] led_pwm_value; // = 240;
  
  reg signed [15:0] delta_value;
  reg signed [15:0] delta_threshold;
  

  assign resetn = &resetn_counter;

  always @(posedge clk) begin
    if (!resetn) resetn_counter <= resetn_counter +1;
  end
  
  always @(posedge clk) begin
      delta_value <= pos_count1 - count1;
  end
  
  wire app_resetn;
  
  assign faultn = 0; //fault[0] & fault[1];

  quad_enc quad1(.resetn(app_resetn), .clk(clk), .a(enc1a), .b(enc1b), .count(count1), .faultn(fault[0]), .multiplier(quad_multiplier) );
  //quad_enc quad2(.resetn(resetn), .clk(clk), .a(enc2a), .b(enc2b), .count(count2), .faultn(fault[1]));
  //spi spi0( .clk(clk), .SCK(SCK), .SSEL(SSEL), .MOSI(MOSI), .MISO(MISO), .count(count1), .byte_received(byte_received), .byte_data_received(byte_data_received) );
  
  spi spi0(.clk(clk), .SCK(SCK), .SSEL(SSEL), .MOSI(MOSI), .MISO(MISO), .send_data(spi_send_data), .byte_received(byte_received), .rx_data( {byte_data_received, packet_received} ) );
  
  wire invert_dir = 0;
  
  pos_counter pos_counter1(.resetn(app_resetn), .clk(clk), .step(step1), .dir(dir1), .invert_dir(invert_dir), .count(pos_count1), .multiplier(step_multiplier));

  /*
  sigmadelta_adc adc0(
    .clk(clk),                    
    .rstn(resetn),                   
    .digital_out2(adc_result),            
    .analog_cmp(A0_P),	            
    .analog_out(A0_PWM),             
    .sample_rdy(sample_rdy)
  );
  */
  
/*******
  ADC_top  #(
	.ADC_WIDTH(8),
	.ACCUM_BITS(10),
	.LPF_DEPTH_BITS(3),
	.LPF_DEPTH_BITS(0)
	)
  adc0 (
    .clk_in(clk),
    .rstn(resetn),
    .digital_out(adc_result),
    .analog_cmp(A0_P),
    .analog_out(A0_PWM),
    .sample_rdy(sample_rdy)
  );
  
  assign {LED0, LED1, LED2, LED3} = adc_result[3:0];
  
  *******/
  
  //always @(posedge clk)
  //  response_data = { 24'0, adc_result };
    
    
  

/*
  reg [20:0] cnt;
  initial begin
    enc1a <= 0;
    enc1b <= 0;
    enc2a <= 0;
    enc2b <= 0;
    cnt <= 0;
  end

  reg [3:0] enccntA = 0;
  reg [3:0] enccntB = 4;


  always @(posedge clk)
  begin
    if (!resetn) begin
      cnt <= 0;
      fault[7:2] <= 'b111111;
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
    end
    else begin
      cnt <=0;
      enc2a <= ~enc2a;  //Inject fault in encoder 2
      enc2b <= ~enc2b;
    end
  end
*/

  
  //always @(posedge clk)
  //  if(sample_rdy)
  //    response_data = { 24'0, adc_result };

  always @(posedge clk)
  begin
  if (!resetn)
  begin
    step_multiplier = 5;
    quad_multiplier = 4;
    led_pwm_value = 240;
    LED0 = 1;
    LED1 = 1;
    LED2 = 1;
    LED3 = 1;
    POSITION_INTERRUPT = 0;
    app_resetn = 1;
    delta_threshold = 40;
  end
  else begin

  if( (delta_value > delta_threshold) || ( -delta_value > delta_threshold ) ) begin
    POSITION_INTERRUPT <= 0;
    LED0 <= 0;
  end
  else begin
    POSITION_INTERRUPT <= 1;
    LED0 <= 1;
  end
  
  if(byte_received)
  begin
    //led_pwm_value = byte_data_received;
    
    // 1 - Read Step Position
    if( byte_data_received == 1)
      spi_send_data <= pos_count1;
    
    // 2 - Read Quadrature
    else if( byte_data_received == 2)
      spi_send_data <= count1;
      
    // 3 - SPI Echo
    else if( byte_data_received == 3)
      spi_send_data <= packet_received;
      
    // 4 - Write Quadrature Numerator
    else if( byte_data_received == 4)
      quad_multiplier <= packet_received[7:0];
    
    // 5 - Write Step Numerator
    else if( byte_data_received == 5)
      step_multiplier <= packet_received[7:0];
      
    // 6 - Read Quadrature Numerator  
    else if( byte_data_received == 6)
      spi_send_data <= { 24'0, quad_multiplier };
      
    // 7 - Read Step Numerator
    else if( byte_data_received == 7)
      spi_send_data <= { 24'0, step_multiplier };
      
    // 8 - Reset
    else if( byte_data_received == 8)
    begin
      app_resetn <= 0;
      LED1 <= 0;
    end

    // 9 - ResetN = 1
    else if( byte_data_received == 9)
    begin
      app_resetn <= 1;
      LED1 <= 1;
    end
      
    // 10 - LED3 PWM
    else if( byte_data_received == 10)
      led_pwm_value <= packet_received[7:0];
      
    // 11 - LED3
    else if( byte_data_received == 11)
      LED3 <= 1;
      
    // 12- LED3
    else if( byte_data_received == 12)
      LED3 <= 0;
      
    // 13- LED3
    else if( byte_data_received == 13)
      LED2 <= packet_received[0];
      
    // 14 - Read app_resetn
    else if( byte_data_received == 14)
      spi_send_data <= { 31'0, app_resetn };
      
    // 15 - Read delta_value
    else if( byte_data_received == 15)
      spi_send_data <= delta_value;
      
    // 16 - Read delta_threshold
    else if( byte_data_received == 16)
      spi_send_data <= delta_threshold;
      
    // 17 - Write delta_threshold
    else if( byte_data_received == 17)
      delta_threshold <= packet_received[15:0];
      
    // Default - Read 1234567890
    else
      spi_send_data <= 1234567890;
  end
  end
  end

  //Commented Out 3/23/20 4:11PM
  //PWM pwm0 ( .clk(clk), .PWM_in(led_pwm_value), .PWM_out(LED3) );
  //assign {LED0, LED1, LED2} = count1[3:1];
  //
  
  ///assign {LED0, LED1, LED2, LED3} = byte_data_received[3:0]; //count1[3:0];
  
  //assign {LED4, LED5, LED6, LED7} = count2[3:0];
  
  //always @(posedge clk) if(sample_rdy) response_data = { 24'0, adc_result };
  
  
  //assign {LED0, LED1, LED2, LED3} =  byte_data_received[3:0];
  //assign {LED0, LED1, LED2, LED3} = adc_result[3:0];
  
  //always @(posedge clk)
  //  if(sample_rdy)
  //    assign {LED0, LED1, LED2, LED3} = adc_result[3:0];
    //else
      //assign {LED0, LED1, LED2, LED3} = 4'b0000;
      //response_data = { 24'0, adc_result };


endmodule




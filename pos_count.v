/*  UltiCores -- IP Cores for Mechatronic Control Systems
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
 */

/* quad_enc.v
 * Quadrature decoder inspired by https://www.fpga4fun.com/QuadratureDecoder.html
 * Converted to 32 bit. Added reset and fault logic. Changed some names to fit us.
 */

module pos_counter(
  input resetn,
  input clk,
  input step,
  input dir,
//  input step_on_edge, // If True, count on every step/dir change -Not implemented
  //input step_active_high,  // If true, count when change to high
  input invert_dir, // Changes count up/down direction
  output reg [31:0] count,
  input [7:0] multiplier,
  );

//  wire faultn;
  wire step_active_high = 1;

  reg [2:0] step_buf;  // Hold sample before compare for stability
  reg [1:0] dir_buf;
//  reg active_edge; //

  wire pos_edge = (step_buf[2:1] == 2'b01);
  wire neg_edge = (step_buf[2:1] == 2'b10);
  
//  wire edge_seen = step_buf[1] ^ step_buf[2];  // Did step change during last clock period?
	
//  wire active_edge = ((step & step_active_high) | (step ~| step_active_high)); // Is the edge we are triggering on the correct edge?
//  wire stepped = edge_seen & step_buf[1]; // If the edge was the right polarity
  wire direction = dir_buf[1] ^ invert_dir;  //Direction determined by buffered input and config register

  always @(posedge clk) begin
    step_buf <= {step_buf[1:0], step};  //Shift new step in. Last 2 samples shift to bits 2 and 1 
    dir_buf <= {dir_buf[0], dir};  //Shift new dir in
//    if (step_active_high)	
//	  active_edge <= step;
//    else 
//	  active_edge <= ~step;

    if (!resetn) begin
      count <= 0;  //reset count
    end
    else begin
      if (step_active_high) begin
        if (pos_edge) begin
          if (direction) 
            count <= count + multiplier;
          else 
            count <= count - multiplier;
        end
      end
      else begin
        if (neg_edge) begin
          if (direction) 
            count <= count + multiplier;
          else 
            count <= count - multiplier;
        end
      end
    end
  end
endmodule

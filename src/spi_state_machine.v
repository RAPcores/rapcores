`default_nettype none

module spi_state_machine(
  input CLK,

  // SPI pins
  input SCK,
  input CS,
  input COPI,
  output CIPO,

  // Step IO
  output step,
  output dir,
  output enable,

  // Stepper Config
  output [2:0] microsteps,
  output [7:0] current,
  output [9:0] config_offtime,
  output [7:0] config_blanktime,
  output [9:0] config_fastdecay_threshold,
  output [7:0] config_minimum_on_time,
  output [10:0] config_current_threshold,
  output [7:0] config_chargepump_period,
  output config_invert_highside,
  output config_invert_lowside,
  //output [511:0] cos_table,

  // encoder
  input [63:0] encoder_count

  // Event IO
  `ifdef BUFFER_DTR
    ,output BUFFER_DTR
  `endif
  `ifdef MOVE_DONE
    ,output MOVE_DONE
  `endif
  `ifdef HALT
    ,input HALT
  `endif
  `ifdef STEPINPUT
    ,input STEPINPUT
    ,input DIRINPUT
    ,input ENINPUT
  `endif
  `ifdef STEPOUTPUT
    ,output STEPOUTPUT
    ,output DIROUTPUT
    ,output ENOUTPUT
  `endif
);

  `ifdef SPIPLL
    // PLL for SPI Bus
    wire spi_clock;
    wire spipll_locked;
    spi_pll spll (.clock_in(CLK),
                  .clock_out(spi_clock),
                  .locked(spipll_locked));
  `else
    wire spi_clock = CLK;
  `endif

  // Word handler
  // The system operates on 64 bit little endian words
  // This should make it easier to send 64 bit chunks from the host controller
  reg [63:0] word_send_data = 0;
  reg [63:0] word_data_received = 0;

  wire [63:0] word_data_received_w;
  always @(posedge spi_clock)
    word_data_received <= word_data_received_w;

  wire word_received;
  SPIWord word_proc (
                .clk(spi_clock),
                .SCK(SCK),
                .CS(CS),
                .COPI(COPI),
                .CIPO(CIPO),
                .word_send_data(word_send_data),
                .word_received(word_received),
                .word_data_received(word_data_received_w));


  //
  // Stepper Config
  //

  reg [2:0] microsteps = 2;
  reg [7:0] current = 140;
  reg [9:0] config_offtime = 810;
  reg [7:0] config_blanktime = 27;
  reg [9:0] config_fastdecay_threshold = 706;
  reg [7:0] config_minimum_on_time = 54;
  reg [10:0] config_current_threshold = 1024;
  reg [7:0] config_chargepump_period = 91;
  reg config_invert_highside = 0;
  reg config_invert_lowside = 0;
/*
  reg [511:0] cos_table;

  initial begin
    cos_table	 [ 	7	 : 	0	 ] = 	255	;
    cos_table	 [ 	15	 : 	8	 ] = 	255	;
    cos_table	 [ 	23	 : 	16	 ] = 	255	;
    cos_table	 [ 	31	 : 	24	 ] = 	254	;
    cos_table	 [ 	39	 : 	32	 ] = 	254	;
    cos_table	 [ 	47	 : 	40	 ] = 	253	;
    cos_table	 [ 	55	 : 	48	 ] = 	252	;
    cos_table	 [ 	63	 : 	56	 ] = 	251	;
    cos_table	 [ 	71	 : 	64	 ] = 	250	;
    cos_table	 [ 	79	 : 	72	 ] = 	249	;
    cos_table	 [ 	87	 : 	80	 ] = 	247	;
    cos_table	 [ 	95	 : 	88	 ] = 	246	;
    cos_table	 [ 	103	 : 	96	 ] = 	244	;
    cos_table	 [ 	111	 : 	104	 ] = 	242	;
    cos_table	 [ 	119	 : 	112	 ] = 	240	;
    cos_table	 [ 	127	 : 	120	 ] = 	238	;
    cos_table	 [ 	135	 : 	128	 ] = 	236	;
    cos_table	 [ 	143	 : 	136	 ] = 	233	;
    cos_table	 [ 	151	 : 	144	 ] = 	231	;
    cos_table	 [ 	159	 : 	152	 ] = 	228	;
    cos_table	 [ 	167	 : 	160	 ] = 	225	;
    cos_table	 [ 	175	 : 	168	 ] = 	222	;
    cos_table	 [ 	183	 : 	176	 ] = 	219	;
    cos_table	 [ 	191	 : 	184	 ] = 	215	;
    cos_table	 [ 	199	 : 	192	 ] = 	212	;
    cos_table	 [ 	207	 : 	200	 ] = 	208	;
    cos_table	 [ 	215	 : 	208	 ] = 	205	;
    cos_table	 [ 	223	 : 	216	 ] = 	201	;
    cos_table	 [ 	231	 : 	224	 ] = 	197	;
    cos_table	 [ 	239	 : 	232	 ] = 	193	;
    cos_table	 [ 	247	 : 	240	 ] = 	189	;
    cos_table	 [ 	255	 : 	248	 ] = 	185	;
    cos_table	 [ 	263	 : 	256	 ] = 	180	;
    cos_table	 [ 	271	 : 	264	 ] = 	176	;
    cos_table	 [ 	279	 : 	272	 ] = 	171	;
    cos_table	 [ 	287	 : 	280	 ] = 	167	;
    cos_table	 [ 	295	 : 	288	 ] = 	162	;
    cos_table	 [ 	303	 : 	296	 ] = 	157	;
    cos_table	 [ 	311	 : 	304	 ] = 	152	;
    cos_table	 [ 	319	 : 	312	 ] = 	147	;
    cos_table	 [ 	327	 : 	320	 ] = 	142	;
    cos_table	 [ 	335	 : 	328	 ] = 	136	;
    cos_table	 [ 	343	 : 	336	 ] = 	131	;
    cos_table	 [ 	351	 : 	344	 ] = 	126	;
    cos_table	 [ 	359	 : 	352	 ] = 	120	;
    cos_table	 [ 	367	 : 	360	 ] = 	115	;
    cos_table	 [ 	375	 : 	368	 ] = 	109	;
    cos_table	 [ 	383	 : 	376	 ] = 	103	;
    cos_table	 [ 	391	 : 	384	 ] = 	98	;
    cos_table	 [ 	399	 : 	392	 ] = 	92	;
    cos_table	 [ 	407	 : 	400	 ] = 	86	;
    cos_table	 [ 	415	 : 	408	 ] = 	80	;
    cos_table	 [ 	423	 : 	416	 ] = 	74	;
    cos_table	 [ 	431	 : 	424	 ] = 	68	;
    cos_table	 [ 	439	 : 	432	 ] = 	62	;
    cos_table	 [ 	447	 : 	440	 ] = 	56	;
    cos_table	 [ 	455	 : 	448	 ] = 	50	;
    cos_table	 [ 	463	 : 	456	 ] = 	44	;
    cos_table	 [ 	471	 : 	464	 ] = 	37	;
    cos_table	 [ 	479	 : 	472	 ] = 	31	;
    cos_table	 [ 	487	 : 	480	 ] = 	25	;
    cos_table	 [ 	495	 : 	488	 ] = 	19	;
    cos_table	 [ 	503	 : 	496	 ] = 	13	;
    cos_table	 [ 	511	 : 	504	 ] = 	6	;
  end
*/
  //
  // Stepper Timing and Buffer Setup
  //

  // Move buffer
  reg [`MOVE_BUFFER_BITS:0] writemoveind = 0;
  wire [`MOVE_BUFFER_BITS:0] moveind; // set via DDA

  // Latching mechanism for engaging the buffered move.
  reg [`MOVE_BUFFER_SIZE:0] stepready = 0;
  wire [`MOVE_BUFFER_SIZE:0] stepfinished; // set via DDA

  reg [`MOVE_BUFFER_SIZE:0] dir_r = {(`MOVE_BUFFER_SIZE){1'b0}};

  reg [63:0] move_duration [`MOVE_BUFFER_SIZE:0];
  reg signed [63:0] increment [`MOVE_BUFFER_SIZE:0];
  reg signed [63:0] incrementincrement [`MOVE_BUFFER_SIZE:0];

  // initialize DDA mem to zero
  // TODO: This doesn't work
  //initial begin
  //  increment[`MOVE_BUFFER_SIZE:0] <= {(`MOVE_BUFFER_SIZE){64'b0}};
  //  incrementincrement[`MOVE_BUFFER_SIZE:0] <= {(`MOVE_BUFFER_SIZE){64'b0}};
  //  move_duration [`MOVE_BUFFER_SIZE:0] <= {(`MOVE_BUFFER_SIZE){64'b0}};
  //end

  reg [7:0] clock_divisor = 40;  // should be 40 for 400 khz at 16Mhz Clk

  // DDA module input wires determined from buffer
  wire [63:0] move_duration_w = move_duration[moveind];
  wire [63:0] increment_w = increment[moveind];
  wire [63:0] incrementincrement_w = incrementincrement[moveind];

  // Step IO
  wire dda_step;
  reg enable_r = 0;

  // Implement flow control and event pins if specified
  `ifdef BUFFER_DTR
    assign BUFFER_DTR = ~(~stepfinished == stepready);
  `endif

  `ifndef STEPINPUT
    assign dir = dir_r[moveind]; // set direction
    assign step = dda_step;
    assign enable = enable_r;
  `else
    assign dir = dir_r[moveind] ^ DIRINPUT; // set direction
    assign step = dda_step ^ STEPINPUT;
    assign enable = enable_r | ENINPUT;
  `endif

  `ifdef STEPOUTPUT
    assign STEPOUTPUT = step;
    assign DIROUTPUT = dir;
    assign ENOUTPUT = enable;
  `endif

  dda_timer dda (.CLK(CLK),
                .clock_divisor(clock_divisor),
                .move_duration(move_duration_w),
                .increment(increment_w),
                .incrementincrement(incrementincrement_w),
                .stepready(stepready),
                .stepfinished(stepfinished),
                .moveind(moveind),
                .writemoveind(writemoveind),
                .step(dda_step)
                `ifdef HALT
                  ,.halt(HALT)
                `endif
                `ifdef MOVE_DONE
                  ,.move_done(MOVE_DONE)
                `endif
                );

  //
  // State Machine for handling SPI Messages
  //

  reg [7:0] message_word_count = 0;
  reg [7:0] message_header = 0;

  // Encoder
  reg signed [63:0] encoder_store; // Snapshot for SPI comms

  // check if the Header indicated multi-word transfer
  wire awaiting_more_words = (message_header == `CMD_COORDINATED_STEP) |
                             (message_header == `CMD_API_VERSION);
  reg [1:0] word_received_r;

  always @(posedge CLK) begin
    word_received_r <= {word_received_r[0], word_received};
    if (word_received_r == 2'b01) begin
      // Zero out send data register
      word_send_data <= 64'b0;

      // Header Processing
      if (!awaiting_more_words) begin

        // Save CMD header incase multi word transaction
        message_header <= word_data_received[63:56]; // Header is 8 MSB

        // First word so message count zero
        message_word_count <= 1;

        case (word_data_received[63:56])

          // Coordinated Move
          `CMD_COORDINATED_STEP: begin

            // Get Direction Bits
            dir_r[writemoveind] <= word_data_received[0];

            // Store encoder values across all axes Now
            encoder_store <= encoder_count;

          end

          // Motor Enable/disable
          `CMD_MOTOR_ENABLE: begin
            enable_r <= word_data_received[0];
          end

          // Clock divisor (24 bit)
          `CMD_CLK_DIVISOR: begin
            clock_divisor[7:0] <= word_data_received[7:0];
          end

          // Set Microstepping
          `CMD_MOTORCONFIG: begin
            // TODO needs to be power of two
            current[7:0] <= word_data_received[15:8];
            microsteps[2:0] <= word_data_received[2:0];
          end

          // Set Microstepping Parameters
          `CMD_MICROSTEPPER_CONFIG: begin
            config_offtime[9:0] <= word_data_received[39:30];
            config_blanktime[7:0] <= word_data_received[29:22];
            config_fastdecay_threshold[9:0] <= word_data_received[21:12];
            config_minimum_on_time[7:0] <= word_data_received[18:11];
            config_current_threshold[10:0] <= word_data_received[10:0];
          end

          // Set chargepump period
          `CMD_CHARGEPUMP: begin
            config_chargepump_period[7:0] <= word_data_received[7:0];
          end

          // Invert Bridge outputs
          `CMD_BRIDGEINVERT: begin
            config_invert_highside <= word_data_received[1];
            config_invert_lowside <= word_data_received[0];
          end

          // Write to Cosine Table
          // TODO Cosine Net is broken
          //`CMD_COSINE_CONFIG: begin
            //cos_table[word_data_received[35:32]] <= word_data_received[31:0];
            //cos_table[word_data_received[37:32]] <= word_data_received[7:0];
            //cos_table[word_data_received[35:32]+3] <= word_data_received[31:25];
            //cos_table[word_data_received[35:32]+2] <= word_data_received[24:16];
            //cos_table[word_data_received[35:32]+1] <= word_data_received[15:8];
            //cos_table[word_data_received[35:32]] <= word_data_received[7:0];
          //end

          // API Version
          `CMD_API_VERSION: begin
            word_send_data[7:0] <= `VERSION_PATCH;
            word_send_data[15:8] <= `VERSION_MINOR;
            word_send_data[23:16] <= `VERSION_MAJOR;
          end

        endcase

      // Addition Word Processing
      end else begin

        message_word_count <= message_word_count + 1;

        case (message_header)
          // Move Routine
          `CMD_COORDINATED_STEP: begin
            // the first non-header word is the move duration
            case (message_word_count)
              1: begin
                move_duration[writemoveind][63:0] <= word_data_received[63:0];
                //word_send_data[63:0] = last_steps_taken[63:0]; // Prep to send steps
              end
              2: begin
                increment[writemoveind][63:0] <= word_data_received[63:0];
                word_send_data[63:0] <= encoder_store[63:0]; // Prep to send encoder read
              end
              3: begin
                incrementincrement[writemoveind][63:0] <= word_data_received[63:0];
                message_word_count <= 0;
                stepready[writemoveind] <= ~stepready[writemoveind];
                writemoveind <= writemoveind + 1'b1;
                message_header <= 8'b0; // Reset Message Header
                `ifdef FORMAL
                  assert(writemoveind <= `MOVE_BUFFER_SIZE);
                `endif
              end
            endcase
          end // `CMD_COORDINATED_STEP
            // by default reset the message header if it was a two word transaction
            default: message_header <= 8'b0; // Reset Message Header
        endcase
      end
    end
  end



endmodule

\m5_TLV_version 1d --inlineGen --debugSigsYosys --fmtFlatSignals: tl-x.org
\m5
   /**
   This template is for developing Tiny Tapeout designs using Makerchip.
   Verilog, SystemVerilog, and/or TL-Verilog can be used.
   Use of Tiny Tapeout Demo Boards (as virtualized in the VIZ tab) is supported.
   See the corresponding Git repository for build instructions.
   **/

   use(m5-1.0)  // See M5 docs in Makerchip IDE Learn menu.

   // ---SETTINGS---
   var(my_design, tt_um_stevehoover_mc_demo1)  /// Change tt_um_example to tt_um_<your-github-username>_<name-of-your-project>. (See README.md.)
   var(target, ASIC) /// Use "FPGA" for TT03 Demo Boards (without bidirectional I/Os).
   var(in_fpga, 1)   /// 1 to include the demo board visualization. (Note: Logic will be under /fpga_pins/fpga.)
   var(vga, 1)       /// 1 for a VGA design on the Tiny VGA Pmod (uo_out): drive R, G and B (all [1:0]; see tt_vga() in tiny_tapeout_lib.tlv)
                     /// Enables VGA features in Makerchip.
   var(vga_makerchip_scale, 1)
                     /// In Makerchip only, divide the VGA timing by this (e.g. 8 for 80x60), so whole frames fit in the
                     /// simulation (and its VIZ). Makerchip's TT VGA view then shows the small frame too.
   var(gamepad, 1)   /// 1 or 2: controllers on the Gamepad Pmod (ui_in[6:4]); read gamepad_up, etc. (see tt_gamepad()).
   var(debounce_inputs, 0)
                     /// Legal values:
                     ///   1: Provide synchronization and debouncing on all input signals.
                     ///   0: Don't provide synchronization and debouncing.
                     ///   m5_if_defined_as(MAKERCHIP, 1, 0, 1): Debounce unless in Makerchip.
   // --------------

   // If debouncing, your top module is wrapped within a debouncing module, so it has a different name.
   var(user_module_name, m5_if(m5_debounce_inputs, my_design, m5_my_design))
   var(debounce_cnt, m5_if_defined_as(MAKERCHIP, 1, 8'h03, 8'hff))
   // No TT lab outside of Makerchip.
   if_defined_as(MAKERCHIP, 1, [''], ['m5_set(in_fpga, 0)'])
   var(vga_scale, m5_if_defined_as(MAKERCHIP, 1, m5_vga_makerchip_scale, 1))  // (Read by the library.)
\SV
   // Include Tiny Tapeout Lab.
   m4_include_lib(['https://raw.githubusercontent.com/os-fpga/Virtual-FPGA-Lab/f18361f1ebbf39c6a910cfcee7b40bc1979360fd/tlv_lib/tiny_tapeout_lib.tlv'])

// Your design, in scope /_top (/fpga, in the TT demo board's FPGA, or /top), with the VGA and gamepad support its
// settings ask for.
\TLV my_design(/_top)
   m5_if(m5_vga, ['m5+tt_vga(0)'])  // 0: the pixel latency (see tt_vga()).
   m5_if(m5_gamepad, ['m5+tt_gamepad(/_top, m5_gamepad)'])

   //   #####  #            #   #      #   #  #####  ####   #####
   //     #    #            #   #      #   #  #      #   #  #
   //     #    #      ###   #   #      #####  ####   ####   ####
   //     #    #             # #       #   #  #      #  #   #
   //     #    #####          #        #   #  #####  #   #  #####
   //
   // Your TL-Verilog logic, if any, and optionally \viz_js (for TL-Verilog or Verilog logic), which overlays the
   // demo board's FPGA chip. Inputs: *ui_in[7:0], *uio_in[7:0] (the bits where uio_oe[7:0] is 0). From deeper
   // scopes, reach this one's signals as /_top$sig.

   // =====================================================================================================
   // Desert Dash: an endless runner. Jump the cacti with A, B or up; after a crash, A or start restarts.
   // A 640x480 VGA picture (tt_vga()) and the Gamepad Pmod (tt_gamepad()). Sprites are 8x8 pixels and the
   // score's font 3x5, drawn 4x. The game state changes once per frame ($frame_end); the rest is per pixel.
   // =====================================================================================================
   $reset = *reset;
   $jump = /gamepad[0]$a || /gamepad[0]$b || /gamepad[0]$up;
   $restart = $reset || ($GameOver && (/gamepad[0]$a || /gamepad[0]$start));
   // Pseudo-random bits (a 16-bit LFSR, advanced every cycle).
   $Lfsr[15:0] <= $reset ? 16'hACE1 : {$Lfsr[14:0], $Lfsr[15] ^ $Lfsr[13] ^ $Lfsr[12] ^ $Lfsr[10]};

   // ---- Game state ----
   $FrameCnt[3:0] <= $reset ? 4'd0 : $frame_end ? $FrameCnt + 4'd1 : $RETAIN;
   $step = $frame_end && ! $GameOver;  // A frame of play.
   // The runner's height above the ground, and its upward velocity (signed): a jump rises 120 pixels.
   $on_ground = $Height == 8'd0;
   $height_next[8:0] = {1'b0, $Height} + {{3{$Vel[5]}}, $Vel};
   $Height[7:0] <= $restart ? 8'd0 : ! $step ? $RETAIN : $height_next[8] ? 8'd0 : $height_next[7:0];
   $Vel[5:0] <= $restart ? 6'd0 : ! $step ? $RETAIN :
                $on_ground && $Vel == 6'd0 ? ($jump ? 6'd15 : 6'd0) :
                $height_next[8] ? 6'd0 :  // Landed.
                $Vel - 6'd1;              // Gravity.
   // The score, in decimal, counting 15 a second; the hundreds set the speed (pixels per frame).
   $tick = $step && $FrameCnt[1:0] == 2'b11;
   $Score0[3:0] <= $restart ? 4'd0 : ! $tick ? $RETAIN : $Score0 == 4'd9 ? 4'd0 : $Score0 + 4'd1;
   $carry0 = $tick && $Score0 == 4'd9;
   $Score1[3:0] <= $restart ? 4'd0 : ! $carry0 ? $RETAIN : $Score1 == 4'd9 ? 4'd0 : $Score1 + 4'd1;
   $carry1 = $carry0 && $Score1 == 4'd9;
   $Score2[3:0] <= $restart ? 4'd0 : ! $carry1 ? $RETAIN : $Score2 == 4'd9 ? 4'd0 : $Score2 + 4'd1;
   $carry2 = $carry1 && $Score2 == 4'd9;
   $Score3[3:0] <= $restart ? 4'd0 : ! $carry2 ? $RETAIN : $Score3 == 4'd9 ? 4'd0 : $Score3 + 4'd1;
   $speed[3:0] = $Score3 != 4'd0 ? 4'd10 : 4'd5 + {1'b0, $Score2[3:1]};
   $Scroll[9:0] <= $restart ? 10'd0 : $step ? $Scroll + {6'd0, $speed} : $RETAIN;
   // Two cactus slots, each a single or double cactus at x = $Xpos - 64 (so they can leave the screen). As one
   // leaves, it returns beyond the other by a random, always jumpable, gap.
   /obs[1:0]
      $gone = $Xpos <= {7'd0, /_top$speed};
      $other_x[10:0] = /obs[(#obs + 1) % 2]$Xpos - {7'd0, /_top$speed};
      $after_other[10:0] = $other_x + 11'd352 + {3'd0, /_top$Lfsr[7:0]};
      $Xpos[10:0] <= /_top$restart ? (#obs == 0 ? 11'd840 : 11'd1240) : ! /_top$step ? $RETAIN :
                  ! $gone ? $Xpos - {7'd0, /_top$speed} :
                  $after_other > 11'd704 ? $after_other : 11'd704;
      $Double <= /_top$restart ? 1'b0 : /_top$step && $gone ? /_top$Lfsr[8] : $RETAIN;
   // A crash: a runner pixel drawn over a cactus pixel, during a frame.
   $Hit <= $restart || $frame_end ? 1'b0 : $Hit || ($runner_px && $cactus_px && $video_active);
   $GameOver <= $restart ? 1'b0 : $frame_end && $Hit ? 1'b1 : $RETAIN;

   // ---- Pixels ----
   // The runner (an original critter), at x 80-111, standing on the ground (y 400) at height 0. Its legs
   // alternate as it runs. (Bit 7 is the leftmost pixel.)
   $rx[9:0] = $Hpos - 10'd80;
   $ry[9:0] = $Vpos + {2'd0, $Height} - 10'd368;
   $stride = $on_ground && $FrameCnt[2];
   $runner_row[7:0] =
      $ry[4:2] == 3'd0 ? 8'b00001110 :
      $ry[4:2] == 3'd1 ? 8'b00011011 :
      $ry[4:2] == 3'd2 ? 8'b00011111 :
      $ry[4:2] == 3'd3 ? 8'b10011100 :
      $ry[4:2] == 3'd4 ? 8'b11111110 :
      $ry[4:2] == 3'd5 ? 8'b01111100 :
      $ry[4:2] == 3'd6 ? ($stride ? 8'b00011000 : 8'b00100100) :
                         ($stride ? 8'b00100100 : 8'b00100010);
   $runner_px = $rx < 10'd32 && $ry < 10'd32 && $runner_row[3'd7 - $rx[4:2]];
   // Cacti, standing on the ground.
   $cy[9:0] = $Vpos - 10'd368;
   $cactus_row[7:0] =
      $cy[4:2] == 3'd0 ? 8'b00010000 :
      $cy[4:2] == 3'd1 ? 8'b00010100 :
      $cy[4:2] <= 3'd3 ? 8'b01010100 :
      $cy[4:2] == 3'd4 ? 8'b01111100 :
                         8'b00010000;
   /obs[1:0]
      $cx[10:0] = {1'd0, /_top$Hpos} + 11'd64 - $Xpos;
      $px = $cx < ($Double ? 11'd64 : 11'd32) && /_top$cy < 10'd32 && /_top$cactus_row[3'd7 - $cx[4:2]];
   $cactus_px = /obs[0]$px || /obs[1]$px;
   // The score: four digits at x 560-623, y 16-35, 16 pixels apart.
   $sx[9:0] = $Hpos - 10'd560;
   $sy[9:0] = $Vpos - 10'd16;
   $digit[3:0] = $sx[5:4] == 2'd0 ? $Score3 : $sx[5:4] == 2'd1 ? $Score2 : $sx[5:4] == 2'd2 ? $Score1 : $Score0;
   $glyph[14:0] =  // 3x5, top row first.
      $digit == 4'd0 ? 15'b111_101_101_101_111 :
      $digit == 4'd1 ? 15'b010_110_010_010_111 :
      $digit == 4'd2 ? 15'b111_001_111_100_111 :
      $digit == 4'd3 ? 15'b111_001_111_001_111 :
      $digit == 4'd4 ? 15'b101_101_111_001_001 :
      $digit == 4'd5 ? 15'b111_100_111_001_111 :
      $digit == 4'd6 ? 15'b111_100_111_101_111 :
      $digit == 4'd7 ? 15'b111_001_001_001_001 :
      $digit == 4'd8 ? 15'b111_101_111_101_111 :
                       15'b111_101_111_001_111;
   $font_row[2:0] =
      $sy[4:2] == 3'd0 ? $glyph[14:12] :
      $sy[4:2] == 3'd1 ? $glyph[11:9] :
      $sy[4:2] == 3'd2 ? $glyph[8:6] :
      $sy[4:2] == 3'd3 ? $glyph[5:3] :
                         $glyph[2:0];
   $score_px = $sx < 10'd64 && $sy < 10'd20 && $sx[3:2] != 2'd3 && $font_row[2'd2 - $sx[3:2]];
   // The ground: a line at y 400, then sand with pebbles, scrolling.
   $gx[9:0] = $Hpos + $Scroll;
   $ground = $Vpos >= 10'd400;
   $ground_line = $Vpos[9:1] == 9'd200;
   $pebble = ($gx[8:3] ^ {$Vpos[4:2], $Vpos[7:5]}) == 6'b101101 && $gx[2:1] == 2'b00 && ! $Vpos[1];
   // Colors (2 bits each of red, green and blue), front to back. The sky turns red after a crash.
   {*R, *G, *B} =
      $score_px ? 6'b11_11_11 :
      $runner_px ? ($GameOver ? 6'b10_00_00 : 6'b11_10_00) :
      $cactus_px ? 6'b00_10_00 :
      $ground_line || ($ground && $pebble) ? 6'b10_01_00 :
      $ground ? 6'b11_11_01 :
      $GameOver ? 6'b11_01_01 : 6'b01_10_11;

   /*
   // Connect Tiny Tapeout outputs
   // Uncomment outputs here, and comment/delete them at the end of this file. (uo_out is driven by tt_vga().)
   *uio_out = 8'b0;
   *uio_oe = 8'b0;
   */




// Set up the Tiny Tapeout lab environment.
\TLV tt_lab()
   /* verilator lint_off UNOPTFLAT */
   // Connect Tiny Tapeout I/Os to Virtual FPGA Lab.
   m5+tt_connections()

   // Instantiate the Virtual FPGA Lab.
   m5+board(/top, /fpga, 7, $, , my_design)
   // Label the switch inputs [0..7] (1..8 on the physical switch panel) (bottom-to-top).
   m5+tt_input_labels_viz(['"UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED"'])

\SV


// ================================================
// A simple Makerchip Verilog test bench driving random stimulus.
// Modify the module contents to your needs.
// Only Makerchip's simulation defines MAKERCHIP, so other tools compiling this file (e.g. VGA Playground) skip it.
// ================================================

`ifdef MAKERCHIP
module top(input logic clk, input logic reset, input logic [31:0] cyc_cnt, output logic passed, output logic failed);
   // Tiny tapeout I/O signals.
   logic [7:0] ui_in, uio_in, uo_out, uio_out, uio_oe;
   logic [31:0] r;
   always @(posedge clk) r <= m5_if_defined_as(MAKERCHIP, 1, ['$urandom()'], ['0']);
   assign ui_in = r[7:0];
   assign uio_in = r[15:8];
   wire ena = 1'b1;  // High while the design is selected.
   wire rst_n = ! reset;

   /*
   // Or, to provide specific inputs at specific times...
   // BE SURE TO COMMENT THE ASSIGNMENT OF INPUTS ABOVE.
   // BE SURE TO DRIVE THESE ON THE B-PHASE OF THE CLOCK (ODD STEPS).
   // Driving on the rising clock edge creates a race with the clock that has unpredictable simulation behavior.
   initial begin
      #1  // Drive inputs on the B-phase.
         ui_in = 8'h0;
      #10 // Step past reset.
         ui_in = 8'hFF;
      // ...etc.
   end
   */

   // Instantiate the Tiny Tapeout module.
   m5_my_design tt(.*);

   assign passed = m5_if(m5_vga, ['cyc_cnt > m5_vga_sim_cycles'], ['cyc_cnt > 100']);
   assign failed = 1'b0;
endmodule
`endif

// Provide a wrapper module to debounce input signals if requested.
// TODO: The debounce module is conditioned for TT03.
m5_if(m5_debounce_inputs, ['m5_tt_top(m5_my_design)'])
// The above macro expands to multiple lines. We enter a new \SV block to reset line tracking.
\SV



// The Tiny Tapeout module.
module m5_user_module_name (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

   wire reset = ! rst_n;

   // List all potentially-unused inputs to prevent warnings
   (* keep *) wire _unused = &{ena, clk, reset, ui_in, uio_in, 1'b1};

\TLV
   m5_if(m5_in_fpga, ['m5+tt_lab()'], ['m5+my_design(/top)'])
   m5_if(m5_vga, ['m5+tt_vga_viz()'])

\SV_plus

   //   #   #  #####  ####   ###  #       ###    ####      #   #  #####  ####   #####
   //   #   #  #      #   #   #   #      #   #  #          #   #  #      #   #  #
   //   #   #  ####   ####    #   #      #   #  #  ##      #####  ####   ####   ####
   //    # #   #      #  #    #   #      #   #  #   #      #   #  #      #  #   #
   //     #    #####  #   #  ###  #####   ###    ####      #   #  #####  #   #  #####
   //
   // Your (System)Verilog logic, if any. (Module interface above.)


   // Connect Tiny Tapeout outputs
   m5_if(m5_vga, ['// (uo_out is driven by tt_vga().)'], ['assign uo_out = 8'b0;'])
   assign uio_out = 8'b0;
   assign uio_oe = 8'b0;

endmodule

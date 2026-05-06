/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_audioplayback (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);


// bidir pinouts
//    uio_in            | uio_out
// [7] - start_prog     | [7] - audio_out
// [6] - end_prog       | [6] - unused
// [5] - SD3            | [5] - SD3
// [4] - SD2            | [4] - SD2
// [3] - unused         | [3] - SCK
// [2] - SD1            | [2] - SD1
// [1] - SD0            | [1] - SD0
// [0] - unused         | [0] - CS

  wire pwm_out;

  // All output pins must be assigned. If not used, assign to 0.
  assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  assign uio_out = 0;
  assign uio_oe  = 0;

  assign uo_out[7] = pwm_out;

  pwm u_pwm (
    .clk            (clk),
    .rst_n          (rst_n),
    .sample_i       (sample),
    .pwm_o          (pwm_out)
  );



  // List all unused inputs to prevent warnings
  wire _unused = &{ena, clk, rst_n, 1'b0};

endmodule

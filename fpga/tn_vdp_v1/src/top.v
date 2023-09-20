//--
//-- F18A
//--   A pin-compatible enhanced replacement for the TMS9918A VDP family.
//--   https://dnotq.io
//--

//-- Released under the 3-Clause BSD License:
//--
//-- Copyright 2011-2018 Matthew Hagerty (matthew <at> dnotq <dot> io)
//--
//-- Redistribution and use in source and binary forms, with or without
//-- modification, are permitted provided that the following conditions are met:
//--
//-- 1. Redistributions of source code must retain the above copyright notice,
//-- this list of conditions and the following disclaimer.
//--
//-- 2. Redistributions in binary form must reproduce the above copyright
//-- notice, this list of conditions and the following disclaimer in the
//-- documentation and/or other materials provided with the distribution.
//--
//-- 3. Neither the name of the copyright holder nor the names of its
//-- contributors may be used to endorse or promote products derived from this
//-- software without specific prior written permission.
//--
//-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//-- ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//-- POSSIBILITY OF SUCH DAMAGE.

//-- Version history.  See README.md for details.
//--
//--   V1.9 Dec 31, 2018

//-- Top module to set up the F18A top for use as in a Tang Nano 9K dev board
`define GW_IDE

module top(
    // fpga signals
    input   clk,
    input   rst_n,
    
    // TMS9118A signals
    input   reset_n,
    input   mode,
    input   csw_n,
    input   csr_n,
    output  int_n,
    output   gromclk,
    output   cpuclk,
    inout   [0:7] cd,

    // user inputs
    input   maxspr_n,       // usr1
    input   scnlin_n,       // usr2
    input   gromclk_n,      // usr3
    input   cpuclk_n,       // usr4

    // flash spi ports
    output  flash_clk,
    output  flash_cs,
    output  flash_mosi,
    input   flash_miso,

    // VGA ports
    input  hsync,
    input  vsync,
    output  [3:0] red,
    output  [3:0] grn,
    output  [3:0] blu,

    // hdmi ports
    output  tmds_clk_p,
    output  tmds_clk_n,
    output  [2:0] tmds_d_p,
    output  [2:0] tmds_d_n
);

// clocks
wire clk_100_w;
wire clk_100_lock_w;
wire clk_25_w;
wire clk_125_w;
wire clk_125_lock_w;
wire hdmi_rst_n_w;
wire clk_50_w;

wire clk_7_w;
wire clk_3_w;

// hdmi
wire rgb_vs_w;
wire rgb_hs_w;
wire rgb_de_w;
wire [7:0] rgb_r_w;
wire [7:0] rgb_g_w;
wire [7:0] rgb_b_w;


    CLK_100 clk_100_inst(
        .clkout(clk_100_w), 
        .lock(clk_100_lock_w),
        .reset(~rst_n), 
        .clkin(clk) 
    );

    CLKDIV clk_50_inst (
        .CLKOUT(clk_50_w), 
        .HCLKIN(clk_100_w), 
        .RESETN(clk_100_lock_w),
        .CALIB(1'b1)
    );
    defparam clk_50_inst.DIV_MODE = "2";
    defparam clk_50_inst.GSREN = "false"; 

    CLKDIV clk_25_inst (
        .CLKOUT(clk_25_w),
        .HCLKIN(clk_100_w), 
        .RESETN(clk_100_lock_w),
        .CALIB(1'b1)
    );
    defparam clk_25_inst.DIV_MODE = "4";
    defparam clk_25_inst.GSREN = "false"; 

    CLK_125 clk_125_inst(
        .clkout(clk_125_w), //output clkout
        .lock(clk_125_lock_w), //output lock
        .reset(~clk_100_lock_w), //input reset
        .clkin(clk_25_w) //input clkin
    );


    CLKDIV clk_7_inst (
        .CLKOUT(clk_7_w),
        .HCLKIN(clk_25_w), 
        .RESETN(clk_100_lock_w),
        .CALIB(1'b1)
    );
    defparam clk_7_inst.DIV_MODE = "3.5";
    defparam clk_7_inst.GSREN = "false"; 

    CLKDIV clk_3_inst (
        .CLKOUT(clk_3_w),
        .HCLKIN(clk_7_w), 
        .RESETN(clk_100_lock_w),
        .CALIB(1'b1)
    );
    defparam clk_3_inst.DIV_MODE = "2";
    defparam clk_3_inst.GSREN = "false"; 


wire rst_n_w;
assign rst_n_w = rst_n & clk_100_lock_w & clk_125_lock_w;

assign reset_n_w = rst_n_w & reset_n;

//	DVI_TX dvi_tx_inst(
//		.I_rst_n(reset_n_w), //input I_rst_n
//		.I_serial_clk(clk_125_w), //input I_serial_clk
//		.I_rgb_clk(clk_25_w), //input I_rgb_clk
//		.I_rgb_vs(rgb_vs_w), //input I_rgb_vs
//		.I_rgb_hs(rgb_hs_w), //input I_rgb_hs
//		.I_rgb_de(rgb_de_w), //input I_rgb_de
//		.I_rgb_r(rgb_r_w), //input [7:0] I_rgb_r
//		.I_rgb_g(rgb_g_w), //input [7:0] I_rgb_g
//		.I_rgb_b(rgb_b_w), //input [7:0] I_rgb_b
//		.O_tmds_clk_p(tmds_clk_p), //output O_tmds_clk_p
//		.O_tmds_clk_n(tmds_clk_n), //output O_tmds_clk_n
//		.O_tmds_data_p(tmds_d_p), //output [2:0] O_tmds_data_p
//		.O_tmds_data_n(tmds_d_n) //output [2:0] O_tmds_data_n
//	);

wire blank_w;
wire  hs_w;
wire  vs_w;
wire [3:0] r_w;
wire [3:0] g_w;
wire [3:0] b_w;

assign red = r_w;
assign grn = g_w;
assign blu = b_w;

//assign hsync = hs_w;
//assign vsync = vs_w;

assign rgb_r_w = {r_w, 4'b0};
assign rgb_g_w = {g_w, 4'b0};
assign rgb_b_w = {b_w, 4'b0};
assign rgb_hs_w = hs_w;
assign rgb_vs_w = vs_w;
assign rgb_de_w = ~blank_w; 

wire [0:7] cd_out_s;

   f18a_core f18a_core_inst (
      .clk_100m0_i(clk_50_w),
      .clk_25m0_i(clk_25_w),
      .reset_n_i(reset_n_w),
      .mode_i(mode),
      .csw_n_i(csw_n),
      .csr_n_i(csr_n),
      .int_n_o(int_n),
      .cd_i(cd),
      .cd_o(cd_out_s),
      .red_o(r_w),
      .grn_o(g_w),
      .blu_o(b_w),
      .blank_o(blank_w),
      .hsync_o(hs_w),
      .vsync_o(vs_w),
      .sprite_max_i(maxspr_n),
      .scanlines_i(~scnlin_n),
      .spi_clk_o(flash_clk),
      .spi_cs_o(flash_cs),
      .spi_mosi_o(flash_mosi),
      .spi_miso_i(flash_miso)
   );

   assign cd = csr_n ? 8'bzzzzzzzz : cd_out_s;


reg [2:0] gromtick;
always @(posedge clk_3_w or negedge rst_n_w) begin
    if (rst_n_w == 0) begin
        gromtick = 3'b0;
    end 
    else begin
        gromtick = gromtick + 3'b1;
    end
end

wire cpuclk_w;
assign cpuclk_w = clk_3_w & rst_n_w;
wire gromclk_w;
assign gromclk_w = ~gromtick[2];

assign gromclk = gromclk_n ? cpuclk_w: gromclk_w; 
assign cpuclk = cpuclk_n ? 1'bz : cpuclk_w;

    wire bdir = hsync;
    wire bc1 = vsync;
    wire [7:0] psg_d_o;
    wire [7:0] psg_ch_a_o, psg_ch_b_o, psg_ch_c_o;
    wire [15:0] audio_o;

    YM2149 psg (
        .CLK(clk_50_w),
        .CE(cpuclk_w),
        .RESET(!reset_n_w),
        .BDIR(bdir),
        .BC(bc1),
        .DI(cd),
        .DO(psg_d_o),
        .CHANNEL_A(psg_ch_a_o),
        .CHANNEL_B(psg_ch_b_o),
        .CHANNEL_C(psg_ch_c_o),

        .SEL (1'b0),
        .MODE(1'b0),

        .ACTIVE(),

        .IOA_in (8'b0),
        .IOA_out(),

        .IOB_in (8'b0),
        .IOB_out()
    );

    assign audio_o = (
        ({4'b00, psg_ch_a_o, 4'b00}) + 
        ({4'b00, psg_ch_b_o, 4'b00}) + 
        ({4'b00, psg_ch_c_o, 4'b00}));

    localparam CLKFRQ = 25200;
    localparam AUDIO_RATE=44100;
    localparam AUDIO_BIT_WIDTH = 16;
    localparam AUDIO_CLK_DELAY = CLKFRQ * 1000 / AUDIO_RATE / 2;
    logic [$clog2(AUDIO_CLK_DELAY)-1:0] audio_divider;
    logic clk_audio_w;

    always_ff@(posedge clk_25_w) 
    begin
        if (audio_divider != AUDIO_CLK_DELAY - 1) 
            audio_divider++;
        else begin 
            clk_audio_w <= ~clk_audio_w; 
            audio_divider <= 0; 
        end
    end

    //
    logic[2:0] tmds;
    wire [9:0] cy, frameHeight;
    wire [9:0] cx, frameWidth;

    //reg [15:0] sample; 


    reg [15:0] audio_sample_word [1:0], audio_sample_word0 [1:0];
    always @(posedge clk_25_w) begin       // crossing clock domain
        audio_sample_word0[0] <= audio_o;
        audio_sample_word[0] <= audio_sample_word0[0];
        audio_sample_word0[1] <= audio_o;
        audio_sample_word[1] <= audio_sample_word0[1];
    end

    hdmi #( .VIDEO_ID_CODE(1), 
            .DVI_OUTPUT(0), 
            .VIDEO_REFRESH_RATE(59.94),
            .IT_CONTENT(1),
            .AUDIO_RATE(AUDIO_RATE), 
            .AUDIO_BIT_WIDTH(AUDIO_BIT_WIDTH),
            .VENDOR_NAME({"Unknown", 8'd0}), // Must be 8 bytes null-padded 7-bit ASCII
            .PRODUCT_DESCRIPTION({"FPGA", 96'd0}), // Must be 16 bytes null-padded 7-bit ASCII
            .SOURCE_DEVICE_INFORMATION(8'h00), // See README.md or CTA-861-G for the list of valid codes
            .START_X(0),
            .START_Y(0) )

    hdmi ( .clk_pixel_x5(clk_125_w), 
          .clk_pixel(clk_25_w), 
          .clk_audio(clk_audio_w),
          .rgb({rgb_r_w, rgb_g_w, rgb_b_w}), 
          .reset( ~reset_n_w ),
          .audio_sample_word(audio_sample_word),
          .tmds(tmds), 
          .tmds_clock(tmdsClk), 
          .cx(cx), 
          .cy(cy),
          .frame_width( frameWidth ),
          .frame_height( frameHeight ) );

//     Gowin LVDS output buffer
    ELVDS_OBUF tmds_bufds [3:0] (
        .I({clk_25_w, tmds}),
        .O({tmds_clk_p, tmds_d_p}),
        .OB({tmds_clk_n, tmds_d_n})
    );

endmodule

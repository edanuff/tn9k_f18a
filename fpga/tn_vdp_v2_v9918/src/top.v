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

    output  adc_clk,
    output  adc_cs,
    output  adc_mosi,
    input   adc_miso,

    output  [5:0]   led,

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

wire blank_w;
wire  hs_w;
wire  vs_w;
wire [3:0] r_w;
wire [3:0] g_w;
wire [3:0] b_w;

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
      .sprite_max_i(maxspr_n),
      .scanlines_i(~maxspr_n),
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

    ////
    logic[2:0] tmds;
    wire [9:0] cy, frameHeight;
    wire [9:0] cx, frameWidth;

    reg [15:0] sample; 
    reg [15:0] audio_sample_word [1:0], audio_sample_word0 [1:0];
    always @(posedge clk_25_w) begin       // crossing clock domain
        audio_sample_word0[0] <= sample;
        audio_sample_word[0] <= audio_sample_word0[0];
        audio_sample_word0[1] <= sample;
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

    // Gowin LVDS output buffer
    ELVDS_OBUF tmds_bufds [3:0] (
        .I({clk_25_w, tmds}),
        .O({tmds_clk_p, tmds_d_p}),
        .OB({tmds_clk_n, tmds_d_n})
    );

    reg [11:0] audio_sample;

    SPI_MCP3202 #(
	.SGL(1),        // sets ADC to single ended mode
	.ODD(0)         // sets sample input to channel 0
	)
    SPI_MCP3202 (
	.clk(clk_125_w),                 // 125  MHz 
	.EN(reset_n_w),                  // Enable the SPI core (ACTIVE HIGH)
	.MISO(adc_miso),                // data out of ADC (Dout pin)
	.MOSI(adc_mosi),               // Data into ADC (Din pin)
	.SCK(adc_clk), 	           // SPI clock
	.o_DATA(audio_sample),      // 12 bit word (for other modules)
    .CS(adc_cs),                 // Chip Select
	.DATA_VALID(sample_valid)          // is high when there is a full 12 bit word. 
	); 

    always @(posedge clk_25_w) begin     
        if (sample_valid)
            sample <= { 3'b0, audio_sample[11:2], 3'b0 };
    end


    assign led[5:0] = ~sample[12:7];

endmodule

// (C) 2001-2018 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.



// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera MegaCore Function License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


// $Id: //acds/rel/18.1std/ip/merlin/altera_merlin_router/altera_merlin_router.sv.terp#1 $
// $Revision: #1 $
// $Date: 2018/07/18 $
// $Author: psgswbuild $

// -------------------------------------------------------
// Merlin Router
//
// Asserts the appropriate one-hot encoded channel based on 
// either (a) the address or (b) the dest id. The DECODER_TYPE
// parameter controls this behaviour. 0 means address decoder,
// 1 means dest id decoder.
//
// In the case of (a), it also sets the destination id.
// -------------------------------------------------------

`timescale 1 ns / 1 ns

module soc_system_mm_interconnect_0_router_001_default_decode
  #(
     parameter DEFAULT_CHANNEL = 37,
               DEFAULT_WR_CHANNEL = -1,
               DEFAULT_RD_CHANNEL = -1,
               DEFAULT_DESTID = 25 
   )
  (output [87 - 82 : 0] default_destination_id,
   output [45-1 : 0] default_wr_channel,
   output [45-1 : 0] default_rd_channel,
   output [45-1 : 0] default_src_channel
  );

  assign default_destination_id = 
    DEFAULT_DESTID[87 - 82 : 0];

  generate
    if (DEFAULT_CHANNEL == -1) begin : no_default_channel_assignment
      assign default_src_channel = '0;
    end
    else begin : default_channel_assignment
      assign default_src_channel = 45'b1 << DEFAULT_CHANNEL;
    end
  endgenerate

  generate
    if (DEFAULT_RD_CHANNEL == -1) begin : no_default_rw_channel_assignment
      assign default_wr_channel = '0;
      assign default_rd_channel = '0;
    end
    else begin : default_rw_channel_assignment
      assign default_wr_channel = 45'b1 << DEFAULT_WR_CHANNEL;
      assign default_rd_channel = 45'b1 << DEFAULT_RD_CHANNEL;
    end
  endgenerate

endmodule


module soc_system_mm_interconnect_0_router_001
(
    // -------------------
    // Clock & Reset
    // -------------------
    input clk,
    input reset,

    // -------------------
    // Command Sink (Input)
    // -------------------
    input                       sink_valid,
    input  [101-1 : 0]    sink_data,
    input                       sink_startofpacket,
    input                       sink_endofpacket,
    output                      sink_ready,

    // -------------------
    // Command Source (Output)
    // -------------------
    output                          src_valid,
    output reg [101-1    : 0] src_data,
    output reg [45-1 : 0] src_channel,
    output                          src_startofpacket,
    output                          src_endofpacket,
    input                           src_ready
);

    // -------------------------------------------------------
    // Local parameters and variables
    // -------------------------------------------------------
    localparam PKT_ADDR_H = 53;
    localparam PKT_ADDR_L = 36;
    localparam PKT_DEST_ID_H = 87;
    localparam PKT_DEST_ID_L = 82;
    localparam PKT_PROTECTION_H = 91;
    localparam PKT_PROTECTION_L = 89;
    localparam ST_DATA_W = 101;
    localparam ST_CHANNEL_W = 45;
    localparam DECODER_TYPE = 0;

    localparam PKT_TRANS_WRITE = 56;
    localparam PKT_TRANS_READ  = 57;

    localparam PKT_ADDR_W = PKT_ADDR_H-PKT_ADDR_L + 1;
    localparam PKT_DEST_ID_W = PKT_DEST_ID_H-PKT_DEST_ID_L + 1;



    // -------------------------------------------------------
    // Figure out the number of bits to mask off for each slave span
    // during address decoding
    // -------------------------------------------------------
    localparam PAD0 = log2ceil(64'h20 - 64'h10); 
    localparam PAD1 = log2ceil(64'h30 - 64'h20); 
    localparam PAD2 = log2ceil(64'h40 - 64'h30); 
    localparam PAD3 = log2ceil(64'h50 - 64'h40); 
    localparam PAD4 = log2ceil(64'h60 - 64'h50); 
    localparam PAD5 = log2ceil(64'h70 - 64'h60); 
    localparam PAD6 = log2ceil(64'h80 - 64'h70); 
    localparam PAD7 = log2ceil(64'h90 - 64'h80); 
    localparam PAD8 = log2ceil(64'ha0 - 64'h90); 
    localparam PAD9 = log2ceil(64'hb0 - 64'ha0); 
    localparam PAD10 = log2ceil(64'hc0 - 64'hb0); 
    localparam PAD11 = log2ceil(64'hd0 - 64'hc0); 
    localparam PAD12 = log2ceil(64'he0 - 64'hd0); 
    localparam PAD13 = log2ceil(64'hf0 - 64'he0); 
    localparam PAD14 = log2ceil(64'h100 - 64'hf0); 
    localparam PAD15 = log2ceil(64'h110 - 64'h100); 
    localparam PAD16 = log2ceil(64'h120 - 64'h110); 
    localparam PAD17 = log2ceil(64'h130 - 64'h120); 
    localparam PAD18 = log2ceil(64'h140 - 64'h130); 
    localparam PAD19 = log2ceil(64'h150 - 64'h140); 
    localparam PAD20 = log2ceil(64'h160 - 64'h150); 
    localparam PAD21 = log2ceil(64'h170 - 64'h160); 
    localparam PAD22 = log2ceil(64'h180 - 64'h170); 
    localparam PAD23 = log2ceil(64'h190 - 64'h180); 
    localparam PAD24 = log2ceil(64'h1a0 - 64'h190); 
    localparam PAD25 = log2ceil(64'h1b0 - 64'h1a0); 
    localparam PAD26 = log2ceil(64'h1c0 - 64'h1b0); 
    localparam PAD27 = log2ceil(64'h1d0 - 64'h1c0); 
    localparam PAD28 = log2ceil(64'h1e0 - 64'h1d0); 
    localparam PAD29 = log2ceil(64'h1f0 - 64'h1e0); 
    localparam PAD30 = log2ceil(64'h200 - 64'h1f0); 
    localparam PAD31 = log2ceil(64'h1008 - 64'h1000); 
    localparam PAD32 = log2ceil(64'h3010 - 64'h3000); 
    localparam PAD33 = log2ceil(64'h4010 - 64'h4000); 
    localparam PAD34 = log2ceil(64'h5010 - 64'h5000); 
    localparam PAD35 = log2ceil(64'h6010 - 64'h6000); 
    localparam PAD36 = log2ceil(64'h7010 - 64'h7000); 
    localparam PAD37 = log2ceil(64'h8010 - 64'h8000); 
    localparam PAD38 = log2ceil(64'h9010 - 64'h9000); 
    localparam PAD39 = log2ceil(64'ha010 - 64'ha000); 
    localparam PAD40 = log2ceil(64'hb010 - 64'hb000); 
    localparam PAD41 = log2ceil(64'h20008 - 64'h20000); 
    // -------------------------------------------------------
    // Work out which address bits are significant based on the
    // address range of the slaves. If the required width is too
    // large or too small, we use the address field width instead.
    // -------------------------------------------------------
    localparam ADDR_RANGE = 64'h20008;
    localparam RANGE_ADDR_WIDTH = log2ceil(ADDR_RANGE);
    localparam OPTIMIZED_ADDR_H = (RANGE_ADDR_WIDTH > PKT_ADDR_W) ||
                                  (RANGE_ADDR_WIDTH == 0) ?
                                        PKT_ADDR_H :
                                        PKT_ADDR_L + RANGE_ADDR_WIDTH - 1;

    localparam RG = RANGE_ADDR_WIDTH-1;
    localparam REAL_ADDRESS_RANGE = OPTIMIZED_ADDR_H - PKT_ADDR_L;

      reg [PKT_ADDR_W-1 : 0] address;
      always @* begin
        address = {PKT_ADDR_W{1'b0}};
        address [REAL_ADDRESS_RANGE:0] = sink_data[OPTIMIZED_ADDR_H : PKT_ADDR_L];
      end   

    // -------------------------------------------------------
    // Pass almost everything through, untouched
    // -------------------------------------------------------
    assign sink_ready        = src_ready;
    assign src_valid         = sink_valid;
    assign src_startofpacket = sink_startofpacket;
    assign src_endofpacket   = sink_endofpacket;
    wire [PKT_DEST_ID_W-1:0] default_destid;
    wire [45-1 : 0] default_src_channel;




    // -------------------------------------------------------
    // Write and read transaction signals
    // -------------------------------------------------------
    wire read_transaction;
    assign read_transaction  = sink_data[PKT_TRANS_READ];


    soc_system_mm_interconnect_0_router_001_default_decode the_default_decode(
      .default_destination_id (default_destid),
      .default_wr_channel   (),
      .default_rd_channel   (),
      .default_src_channel  (default_src_channel)
    );

    always @* begin
        src_data    = sink_data;
        src_channel = default_src_channel;
        src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = default_destid;

        // --------------------------------------------------
        // Address Decoder
        // Sets the channel and destination ID based on the address
        // --------------------------------------------------

    // ( 0x10 .. 0x20 )
    if ( {address[RG:PAD0],{PAD0{1'b0}}} == 18'h10   ) begin
            src_channel = 45'b000010000000000000000000000000000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 25;
    end

    // ( 0x20 .. 0x30 )
    if ( {address[RG:PAD1],{PAD1{1'b0}}} == 18'h20   ) begin
            src_channel = 45'b000001000000000000000000000000000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 24;
    end

    // ( 0x30 .. 0x40 )
    if ( {address[RG:PAD2],{PAD2{1'b0}}} == 18'h30   ) begin
            src_channel = 45'b000000100000000000000000000000000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 22;
    end

    // ( 0x40 .. 0x50 )
    if ( {address[RG:PAD3],{PAD3{1'b0}}} == 18'h40   ) begin
            src_channel = 45'b000000010000000000000000000000000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 21;
    end

    // ( 0x50 .. 0x60 )
    if ( {address[RG:PAD4],{PAD4{1'b0}}} == 18'h50   ) begin
            src_channel = 45'b000000001000000000000000000000000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 20;
    end

    // ( 0x60 .. 0x70 )
    if ( {address[RG:PAD5],{PAD5{1'b0}}} == 18'h60   ) begin
            src_channel = 45'b000000000100000000000000000000000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 19;
    end

    // ( 0x70 .. 0x80 )
    if ( {address[RG:PAD6],{PAD6{1'b0}}} == 18'h70   ) begin
            src_channel = 45'b000000000010000000000000000000000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 18;
    end

    // ( 0x80 .. 0x90 )
    if ( {address[RG:PAD7],{PAD7{1'b0}}} == 18'h80   ) begin
            src_channel = 45'b000000000001000000000000000000000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 17;
    end

    // ( 0x90 .. 0xa0 )
    if ( {address[RG:PAD8],{PAD8{1'b0}}} == 18'h90   ) begin
            src_channel = 45'b000000000000100000000000000000000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 16;
    end

    // ( 0xa0 .. 0xb0 )
    if ( {address[RG:PAD9],{PAD9{1'b0}}} == 18'ha0   ) begin
            src_channel = 45'b000000000000010000000000000000000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 15;
    end

    // ( 0xb0 .. 0xc0 )
    if ( {address[RG:PAD10],{PAD10{1'b0}}} == 18'hb0   ) begin
            src_channel = 45'b000000000000001000000000000000000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 14;
    end

    // ( 0xc0 .. 0xd0 )
    if ( {address[RG:PAD11],{PAD11{1'b0}}} == 18'hc0   ) begin
            src_channel = 45'b000000000000000100000000000000000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 13;
    end

    // ( 0xd0 .. 0xe0 )
    if ( {address[RG:PAD12],{PAD12{1'b0}}} == 18'hd0   ) begin
            src_channel = 45'b000000000000000010000000000000000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 11;
    end

    // ( 0xe0 .. 0xf0 )
    if ( {address[RG:PAD13],{PAD13{1'b0}}} == 18'he0   ) begin
            src_channel = 45'b000000000000000001000000000000000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 10;
    end

    // ( 0xf0 .. 0x100 )
    if ( {address[RG:PAD14],{PAD14{1'b0}}} == 18'hf0   ) begin
            src_channel = 45'b000000000000000000100000000000000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 9;
    end

    // ( 0x100 .. 0x110 )
    if ( {address[RG:PAD15],{PAD15{1'b0}}} == 18'h100   ) begin
            src_channel = 45'b000000000000000000010000000000000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 8;
    end

    // ( 0x110 .. 0x120 )
    if ( {address[RG:PAD16],{PAD16{1'b0}}} == 18'h110   ) begin
            src_channel = 45'b000000000000000000001000000000000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 7;
    end

    // ( 0x120 .. 0x130 )
    if ( {address[RG:PAD17],{PAD17{1'b0}}} == 18'h120   ) begin
            src_channel = 45'b000000000000000000000100000000000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 6;
    end

    // ( 0x130 .. 0x140 )
    if ( {address[RG:PAD18],{PAD18{1'b0}}} == 18'h130   ) begin
            src_channel = 45'b000000000000000000000010000000000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 5;
    end

    // ( 0x140 .. 0x150 )
    if ( {address[RG:PAD19],{PAD19{1'b0}}} == 18'h140   ) begin
            src_channel = 45'b000000000000000000000001000000000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 4;
    end

    // ( 0x150 .. 0x160 )
    if ( {address[RG:PAD20],{PAD20{1'b0}}} == 18'h150   ) begin
            src_channel = 45'b000000000000000000000000100000000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 3;
    end

    // ( 0x160 .. 0x170 )
    if ( {address[RG:PAD21],{PAD21{1'b0}}} == 18'h160   ) begin
            src_channel = 45'b000000000000000000000000010000000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 2;
    end

    // ( 0x170 .. 0x180 )
    if ( {address[RG:PAD22],{PAD22{1'b0}}} == 18'h170   ) begin
            src_channel = 45'b000000000000000000000000001000000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 32;
    end

    // ( 0x180 .. 0x190 )
    if ( {address[RG:PAD23],{PAD23{1'b0}}} == 18'h180   ) begin
            src_channel = 45'b000000000000000000000000000100000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 31;
    end

    // ( 0x190 .. 0x1a0 )
    if ( {address[RG:PAD24],{PAD24{1'b0}}} == 18'h190   ) begin
            src_channel = 45'b000000000000000000000000000010000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 30;
    end

    // ( 0x1a0 .. 0x1b0 )
    if ( {address[RG:PAD25],{PAD25{1'b0}}} == 18'h1a0   ) begin
            src_channel = 45'b000000000000000000000000000001000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 29;
    end

    // ( 0x1b0 .. 0x1c0 )
    if ( {address[RG:PAD26],{PAD26{1'b0}}} == 18'h1b0   ) begin
            src_channel = 45'b000000000000000000000000000000100000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 28;
    end

    // ( 0x1c0 .. 0x1d0 )
    if ( {address[RG:PAD27],{PAD27{1'b0}}} == 18'h1c0   ) begin
            src_channel = 45'b000000000000000000000000000000010000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 27;
    end

    // ( 0x1d0 .. 0x1e0 )
    if ( {address[RG:PAD28],{PAD28{1'b0}}} == 18'h1d0   ) begin
            src_channel = 45'b000000000000000000000000000000001000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 26;
    end

    // ( 0x1e0 .. 0x1f0 )
    if ( {address[RG:PAD29],{PAD29{1'b0}}} == 18'h1e0   ) begin
            src_channel = 45'b000000000000000000000000000000000100000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 23;
    end

    // ( 0x1f0 .. 0x200 )
    if ( {address[RG:PAD30],{PAD30{1'b0}}} == 18'h1f0   ) begin
            src_channel = 45'b000100000000000000000000000000000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 39;
    end

    // ( 0x1000 .. 0x1008 )
    if ( {address[RG:PAD31],{PAD31{1'b0}}} == 18'h1000  && read_transaction  ) begin
            src_channel = 45'b000000000000000000000000000000000000000010;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 43;
    end

    // ( 0x3000 .. 0x3010 )
    if ( {address[RG:PAD32],{PAD32{1'b0}}} == 18'h3000   ) begin
            src_channel = 45'b000000000000000000000000000000000000000100;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 36;
    end

    // ( 0x4000 .. 0x4010 )
    if ( {address[RG:PAD33],{PAD33{1'b0}}} == 18'h4000   ) begin
            src_channel = 45'b000000000000000000000000000000000000001000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 42;
    end

    // ( 0x5000 .. 0x5010 )
    if ( {address[RG:PAD34],{PAD34{1'b0}}} == 18'h5000   ) begin
            src_channel = 45'b000000000000000000000000000000000000010000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 1;
    end

    // ( 0x6000 .. 0x6010 )
    if ( {address[RG:PAD35],{PAD35{1'b0}}} == 18'h6000   ) begin
            src_channel = 45'b000000000000000000000000000000000001000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 12;
    end

    // ( 0x7000 .. 0x7010 )
    if ( {address[RG:PAD36],{PAD36{1'b0}}} == 18'h7000   ) begin
            src_channel = 45'b000000000000000000000000000000000010000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 33;
    end

    // ( 0x8000 .. 0x8010 )
    if ( {address[RG:PAD37],{PAD37{1'b0}}} == 18'h8000   ) begin
            src_channel = 45'b000000000000000000000000000000000000100000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 34;
    end

    // ( 0x9000 .. 0x9010 )
    if ( {address[RG:PAD38],{PAD38{1'b0}}} == 18'h9000   ) begin
            src_channel = 45'b001000000000000000000000000000000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 40;
    end

    // ( 0xa000 .. 0xa010 )
    if ( {address[RG:PAD39],{PAD39{1'b0}}} == 18'ha000   ) begin
            src_channel = 45'b010000000000000000000000000000000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 41;
    end

    // ( 0xb000 .. 0xb010 )
    if ( {address[RG:PAD40],{PAD40{1'b0}}} == 18'hb000   ) begin
            src_channel = 45'b100000000000000000000000000000000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 0;
    end

    // ( 0x20000 .. 0x20008 )
    if ( {address[RG:PAD41],{PAD41{1'b0}}} == 18'h20000   ) begin
            src_channel = 45'b000000000000000000000000000000000000000001;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 35;
    end

end


    // --------------------------------------------------
    // Ceil(log2()) function
    // --------------------------------------------------
    function integer log2ceil;
        input reg[65:0] val;
        reg [65:0] i;

        begin
            i = 1;
            log2ceil = 0;

            while (i < val) begin
                log2ceil = log2ceil + 1;
                i = i << 1;
            end
        end
    endfunction

endmodule



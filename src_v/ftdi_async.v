//-----------------------------------------------------------------
//                       FTDI FIFO -> AXI Bridge
//                              V1.0
//                        Ultra-Embedded.com
//                        Copyright 2015-2019
//
//                 Email: admin@ultra-embedded.com
//
//                         License: GPL
// If you would like a version with a more permissive license for
// use in closed source commercial applications please contact me
// for details.
//-----------------------------------------------------------------
//
// This file is open source HDL; you can redistribute it and/or 
// modify it under the terms of the GNU General Public License as 
// published by the Free Software Foundation; either version 2 of 
// the License, or (at your option) any later version.
//
// This file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public 
// License along with this file; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
// USA
//-----------------------------------------------------------------

//-----------------------------------------------------------------
//                          Generated File
//-----------------------------------------------------------------

module ftdi_async
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
     parameter CLK_DIV          = 2
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input           clk_i
    ,input           rst_i
    ,input           ftdi_rxf_i
    ,input           ftdi_txe_i
    ,input  [  7:0]  ftdi_data_in_i
    ,input           inport_valid_i
    ,input  [  7:0]  inport_data_i
    ,input           outport_accept_i

    // Outputs
    ,output          ftdi_siwua_o
    ,output          ftdi_wrn_o
    ,output          ftdi_rdn_o
    ,output          ftdi_oen_o
    ,output [  7:0]  ftdi_data_out_o
    ,output          inport_accept_o
    ,output          outport_valid_o
    ,output [  7:0]  outport_data_o
);



//-----------------------------------------------------------------
// Defines / Local params
//-----------------------------------------------------------------
localparam STATE_W           = 2;
localparam STATE_IDLE        = 2'd0;
localparam STATE_TX_SETUP    = 2'd1;
localparam STATE_TX          = 2'd2;
localparam STATE_RX          = 2'd3;

//-----------------------------------------------------------------
// Registers / Wires
//-----------------------------------------------------------------

// Xilinx placement pragmas:
//synthesis attribute IOB of tx_data_q is "TRUE"
//synthesis attribute IOB of ftdi_rd_q is "TRUE"
//synthesis attribute IOB of ftdi_wr_q is "TRUE"

// Current state
reg [STATE_W-1:0]      state_q;

reg                    tx_ready_q;

reg                    ftdi_rxf_ms_q;
reg                    ftdi_txe_ms_q;
reg                    ftdi_rxf_q;
reg                    ftdi_txe_q;

reg [7:0]              rx_data_q;
reg [7:0]              tx_data_q;

//-----------------------------------------------------------------
// Resample async signals
//-----------------------------------------------------------------
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    ftdi_rxf_ms_q   <= 1'b1;
    ftdi_txe_ms_q   <= 1'b1;
    ftdi_rxf_q      <= 1'b1;
    ftdi_txe_q      <= 1'b1;
end
else
begin
    ftdi_rxf_q      <= ftdi_rxf_ms_q;
    ftdi_rxf_ms_q   <= ftdi_rxf_i;

    ftdi_txe_q      <= ftdi_txe_ms_q;
    ftdi_txe_ms_q   <= ftdi_txe_i;
end

//-----------------------------------------------------------------
// Clock divider
//-----------------------------------------------------------------
reg [CLK_DIV:0] clk_div_q;

always @ (posedge rst_i or posedge clk_i)
if (rst_i)
    clk_div_q <= {1'b1, {(CLK_DIV){1'b0}}};
else if (CLK_DIV > 0)
    clk_div_q <= {clk_div_q[0], clk_div_q[CLK_DIV:1]};
else
    clk_div_q <= ~clk_div_q;

wire clk_en_w = clk_div_q[0];

//-----------------------------------------------------------------
// Sample flag
//-----------------------------------------------------------------
// Sample read data when both RD# and RXF# are low
wire rx_sample_w = (state_q == STATE_RX) & clk_en_w;

// Target accepts data when WR# and TXE# are low
wire tx_sent_w   = (state_q == STATE_TX) & clk_en_w;

wire rx_ready_w = ~ftdi_rxf_q & clk_en_w;
wire tx_space_w = ~ftdi_txe_q & clk_en_w;

wire rx_start_w  = (state_q == STATE_IDLE) & rx_ready_w & !outport_valid_o;
wire tx_start_w  = (state_q == STATE_IDLE) & tx_space_w & tx_ready_q;

//-----------------------------------------------------------------
// Next State Logic
//-----------------------------------------------------------------
reg [STATE_W-1:0] next_state_r;
always @ *
begin
    next_state_r = state_q;

    case (state_q)
    //-----------------------------------------
    // STATE_IDLE
    //-----------------------------------------
    STATE_IDLE :
    begin
        if (rx_start_w)
            next_state_r    = STATE_RX;
        else if (tx_start_w)
            next_state_r    = STATE_TX_SETUP;
    end
    //-----------------------------------------
    // STATE_RX
    //-----------------------------------------
    STATE_RX :
    begin
        if (clk_en_w)
            next_state_r  = STATE_IDLE;
    end
    //-----------------------------------------
    // STATE_TX_SETUP
    //-----------------------------------------
    STATE_TX_SETUP :
    begin
        if (clk_en_w)
            next_state_r  = STATE_TX;
    end
    //-----------------------------------------
    // STATE_TX
    //-----------------------------------------
    STATE_TX :
    begin
        if (clk_en_w)
            next_state_r  = STATE_IDLE;
    end    
    default:
        ;
   endcase
end

// Update state
always @ (posedge rst_i or posedge clk_i)
if (rst_i)
    state_q   <= STATE_IDLE;
else
    state_q   <= next_state_r;

//-----------------------------------------------------------------
// rd_ready_q
//-----------------------------------------------------------------
reg rd_ready_q;
always @ (posedge rst_i or posedge clk_i)
if (rst_i)
    rd_ready_q <= 1'b0;
else if (rx_sample_w)
    rd_ready_q <= 1'b1;
else if (outport_accept_i)
    rd_ready_q <= 1'b0;

assign outport_valid_o = rd_ready_q;

//-----------------------------------------------------------------
// tx_ready_q
//-----------------------------------------------------------------
always @ (posedge rst_i or posedge clk_i)
if (rst_i)
    tx_ready_q <= 1'b0;
else if (tx_sent_w)
    tx_ready_q <= 1'b0;
else if (inport_valid_i)
    tx_ready_q <= 1'b1;

assign inport_accept_o = !tx_ready_q;

//-----------------------------------------------------------------
// RD#
//-----------------------------------------------------------------
reg ftdi_rd_q;

always @ (posedge rst_i or posedge clk_i)
if (rst_i)
    ftdi_rd_q <= 1'b1;
else if (rx_start_w)
    ftdi_rd_q <= 1'b0;
else if (rx_sample_w)
    ftdi_rd_q <= 1'b1;

assign ftdi_rdn_o = ftdi_rd_q;

//-----------------------------------------------------------------
// WR#
//-----------------------------------------------------------------
reg ftdi_wr_q;

always @ (posedge rst_i or posedge clk_i)
if (rst_i)
    ftdi_wr_q <= 1'b1;
else if ((state_q == STATE_TX_SETUP) && clk_en_w)
    ftdi_wr_q <= 1'b0;
else if (tx_sent_w)
    ftdi_wr_q <= 1'b1;

assign ftdi_wrn_o = ftdi_wr_q;

//-----------------------------------------------------------------
// Rx Data
//-----------------------------------------------------------------
always @ (posedge rst_i or posedge clk_i)
if (rst_i)
    rx_data_q <= 8'b0;
else if (rx_sample_w)
    rx_data_q <= ftdi_data_in_i;

//-----------------------------------------------------------------
// Tx Data
//-----------------------------------------------------------------
always @ (posedge rst_i or posedge clk_i)
if (rst_i)
    tx_data_q <= 8'b0;
else if (inport_valid_i && inport_accept_o)
    tx_data_q <= inport_data_i;

//-----------------------------------------------------------------
// Outputs
//-----------------------------------------------------------------
assign ftdi_oen_o         = ~(state_q == STATE_TX_SETUP || state_q == STATE_TX);
assign ftdi_data_out_o    = tx_data_q;
assign ftdi_siwua_o       = 1'b1;

assign outport_data_o     = rx_data_q;


endmodule

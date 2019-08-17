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

module ftdi_sync
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
// Tx FIFO
//-----------------------------------------------------------------
wire [7:0] tx_data_w;
wire       tx_valid_w;
wire       tx_accept_w;
wire [6:0] tx_level_w;

ftdi_fifo
#(
    .WIDTH(8),
    .DEPTH(64),
    .ADDR_W(6),
    .COUNT_W(7)
)
u_fifo_out
(
    .clk_i(clk_i),
    .rst_i(rst_i),

    .push_i(inport_valid_i),
    .data_in_i(inport_data_i),
    .accept_o(inport_accept_o),

    .valid_o(tx_valid_w),
    .data_out_o(tx_data_w),
    .pop_i(tx_accept_w),
    .level_o(tx_level_w)
);

wire tx_empty_next_w = (tx_level_w <= 7'd1);

//-----------------------------------------------------------------
// Rx FIFO
//-----------------------------------------------------------------
wire [7:0] rx_data_w  = ftdi_data_in_i;
wire       rx_valid_w = !ftdi_rdn_o && !ftdi_rxf_i;
wire       rx_accept_w;
wire [6:0] rx_level_w;

ftdi_fifo
#(
    .WIDTH(8),
    .DEPTH(64),
    .ADDR_W(6),
    .COUNT_W(7)
)
u_fifo_in
(
    .clk_i(clk_i),
    .rst_i(rst_i),

    .push_i(rx_valid_w),
    .data_in_i(rx_data_w),
    .accept_o(rx_accept_w),

    .valid_o(outport_valid_o),
    .data_out_o(outport_data_o),
    .pop_i(outport_accept_i),
    .level_o(rx_level_w)
);

wire rx_full_next_w = (rx_level_w >= 7'd63);

//-----------------------------------------------------------------
// Defines / Local params
//-----------------------------------------------------------------
localparam STATE_W           = 2;
localparam STATE_IDLE        = 2'd0;
localparam STATE_TX          = 2'd1;
localparam STATE_RX          = 2'd2;
reg [STATE_W-1:0] state_q;

wire rx_space_w = rx_accept_w;
wire rx_ready_w = !ftdi_rxf_i;
wire tx_space_w = !ftdi_txe_i;

reg  tx_valid_q;
assign tx_accept_w = !tx_valid_q || (state_q == STATE_TX && tx_space_w);

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    tx_valid_q   <= 1'b0;
else if (tx_accept_w)
    tx_valid_q   <= tx_valid_w;

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
        if (rx_ready_w && rx_space_w)
            next_state_r    = STATE_RX;
        else if (tx_space_w && (tx_valid_w || tx_valid_q))
            next_state_r    = STATE_TX;
    end
    //-----------------------------------------
    // STATE_RX
    //-----------------------------------------
    STATE_RX :
    begin
        if (!rx_ready_w || rx_full_next_w)
            next_state_r  = STATE_IDLE;
    end
    //-----------------------------------------
    // STATE_TX
    //-----------------------------------------
    STATE_TX :
    begin
        if (!tx_space_w || tx_empty_next_w)
            next_state_r  = STATE_IDLE;
    end    
    default:
        ;
   endcase
end

// Update state
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    state_q   <= STATE_IDLE;
else
    state_q   <= next_state_r;

//-----------------------------------------------------------------
// RD/WR/OE
//-----------------------------------------------------------------
// Xilinx placement pragmas:
//synthesis attribute IOB of rdn_q is "TRUE"
//synthesis attribute IOB of wrn_q is "TRUE"
//synthesis attribute IOB of oen_q is "TRUE"
//synthesis attribute IOB of data_q is "TRUE"

reg       rdn_q;
reg       wrn_q;
reg       oen_q;
reg [7:0] data_q;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    oen_q   <= 1'b1;
else if (state_q == STATE_IDLE && next_state_r == STATE_RX)
    oen_q   <= 1'b0;
else if (state_q == STATE_RX && next_state_r == STATE_IDLE)
    oen_q   <= 1'b1;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    rdn_q   <= 1'b1;
else if (state_q == STATE_IDLE && next_state_r == STATE_RX)
    rdn_q   <= 1'b0;
else if (state_q == STATE_RX && next_state_r == STATE_IDLE)
    rdn_q   <= 1'b1;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    wrn_q   <= 1'b1;
else if (state_q == STATE_IDLE && next_state_r == STATE_TX)
    wrn_q   <= 1'b0;
else if (state_q == STATE_TX && next_state_r == STATE_IDLE)
    wrn_q   <= 1'b1;

always @ (posedge clk_i or posedge rst_i)
if (rst_i)
    data_q  <= 8'b0;
else if (tx_accept_w)
    data_q  <= tx_data_w;

assign ftdi_wrn_o      = wrn_q;
assign ftdi_rdn_o      = rdn_q;
assign ftdi_oen_o      = oen_q;
assign ftdi_data_out_o = data_q;
assign ftdi_siwua_o    = 1'b1; // TODO:

endmodule

module ftdi_fifo
//-----------------------------------------------------------------
// Params
//-----------------------------------------------------------------
#(
    parameter WIDTH   = 8,
    parameter DEPTH   = 4,
    parameter ADDR_W  = 2,
    parameter COUNT_W = 3
)
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     input                clk_i
    ,input                rst_i
    ,input  [WIDTH-1:0]   data_in_i
    ,input                push_i
    ,input                pop_i

    // Outputs
    ,output [WIDTH-1:0]   data_out_o
    ,output               accept_o
    ,output               valid_o
    ,output [COUNT_W-1:0] level_o
);

//-----------------------------------------------------------------
// Registers
//-----------------------------------------------------------------
reg [WIDTH-1:0]   ram_q[DEPTH-1:0];
reg [ADDR_W-1:0]  rd_ptr_q;
reg [ADDR_W-1:0]  wr_ptr_q;
reg [COUNT_W-1:0] count_q;

//-----------------------------------------------------------------
// Sequential
//-----------------------------------------------------------------
always @ (posedge clk_i or posedge rst_i)
if (rst_i)
begin
    count_q   <= {(COUNT_W) {1'b0}};
    rd_ptr_q  <= {(ADDR_W) {1'b0}};
    wr_ptr_q  <= {(ADDR_W) {1'b0}};
end
else
begin
    // Push
    if (push_i & accept_o)
    begin
        ram_q[wr_ptr_q] <= data_in_i;
        wr_ptr_q        <= wr_ptr_q + 1;
    end

    // Pop
    if (pop_i & valid_o)
        rd_ptr_q      <= rd_ptr_q + 1;

    // Count up
    if ((push_i & accept_o) & ~(pop_i & valid_o))
        count_q <= count_q + 1;
    // Count down
    else if (~(push_i & accept_o) & (pop_i & valid_o))
        count_q <= count_q - 1;
end

//-------------------------------------------------------------------
// Combinatorial
//-------------------------------------------------------------------
/* verilator lint_off WIDTH */
assign valid_o       = (count_q != 0);
assign accept_o      = (count_q != DEPTH);
/* verilator lint_on WIDTH */

assign data_out_o    = ram_q[rd_ptr_q];
assign level_o       = count_q;



endmodule

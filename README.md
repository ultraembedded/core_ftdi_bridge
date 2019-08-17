### FTDI FT245 Style Synchronous/Asynchronous FIFO Bridge

Github:   [https://github.com/ultraembedded/core_ftdi_bridge](https://github.com/ultraembedded/core_ftdi_bridge)

This component provides a bridge from the FTDI Asynchronous or Synchronous FIFO interface (such as found on the FT245 or FT2232) to an AXI4 master & GPIO interface.

Devices such as the FT2232 must be switched into FIFO mode using the FT_PROG EEPROM programming tool from FTDI.  
The choice between asychronous and synchronous mode for FTDI devices which support it are done at runtime via the ftdi_set_bitmode API.

This component supports reads and writes down to byte level granularity.

##### Supported FTDI devices

| FTDI Device | Num Channels | Async FIFO Support | Sync FIFO Support |
| ----------- | ------------ | ------------------ | ----------------- | 
| FT245B      |      1       |       True         |      False        |
| FT245R      |      1       |       True         |      False        |
| FT240X      |      1       |       True         |      False        |
| FT2232D     |      2       |       True         |      False        |
| FT232H      |      1       |       True         |      True         |
| FT2232H     |      2       |       True         |      True         |

See [TN_167 FIFO Basics](https://www.ftdichip.com/Support/Documents/TechnicalNotes/TN_167_FIFO_Basics.pdf) from FTDI for more details.

##### Testing

Verified under simulation and validated on FPGA.  
Used on the miniSpartan6+ board which uses the FTDI FT2232HL (asynchronous mode), and using an Xilinx Artix 7 board with FTDI FT2232HL (synchronous mode).

##### Configuration
* Top: ftdi_bridge
* Clock: clk_i - Must be sourced from FTDI device for mode = SYNC
* Reset: rst_i - Asynchronous, active high
* parameter MODE - "SYNC" or "ASYNC" FT245 mode
* parameter CLK_DIV - Clock divider (minimum is 2) (only valid for MODE="ASYNC")
* parameter GP_OUTPUTS - Number of GPIO outputs (1 - 8)
* parameter GP_INPUTS - Number of GPIO inputs (1 - 8)
* parameter AXI_ID - AXI ID to use

##### Size / Speed

For asynchronous mode;
* ~220 flops / 320 LUTs (Spartan 6)
* ~200MHz on Xilinx Spartan 6 LX9 (speed -3)

For synchronous mode;
* ~275 flops / 598 LUTs (Spartan 6)
* ~165MHz on Xilinx Spartan 6 LX9 (speed -3)

##### Example Instantiation

This example works well for Xilinx FPGAs;
```
wire [7:0] ftdi_data_in_w;
wire [7:0] ftdi_data_out_w;

ftdi_bridge
#(
	.MODE("SYNC")
)
u_bridge
(
     .clk_i(ftdi_clk_i)
    ,.rst_i(rst)

    ,.mem_awvalid_o(...)
    ,.mem_awaddr_o(...)
    ,.mem_awid_o(...)
    ,.mem_awlen_o(...)
    ,.mem_awburst_o(...)
    ,.mem_wvalid_o(...)
    ,.mem_wdata_o(...)
    ,.mem_wstrb_o(...)
    ,.mem_wlast_o(...)
    ,.mem_bready_o(...)
    ,.mem_arvalid_o(...)
    ,.mem_araddr_o(...)
    ,.mem_arid_o(...)
    ,.mem_arlen_o(...)
    ,.mem_arburst_o(...)
    ,.mem_rready_o(...)    
    ,.mem_awready_i(...)
    ,.mem_wready_i(...)
    ,.mem_bvalid_i(...)
    ,.mem_bresp_i(...)
    ,.mem_bid_i(...)
    ,.mem_arready_i(...)
    ,.mem_rvalid_i(...)
    ,.mem_rdata_i(...)
    ,.mem_rresp_i(...)
    ,.mem_rid_i(...)
    ,.mem_rlast_i(...)

    ,.ftdi_rxf_i(ftdi_rxf_i)
    ,.ftdi_txe_i(ftdi_txe_i)
    ,.ftdi_data_in_i(ftdi_data_in_w)
    ,.ftdi_siwua_o(ftdi_siwua_o)
    ,.ftdi_wrn_o(ftdi_wrn_o)
    ,.ftdi_rdn_o(ftdi_rdn_o)
    ,.ftdi_oen_o(ftdi_oen_o)
    ,.ftdi_data_out_o(ftdi_data_out_w)

);

assign ftdi_data_in_w = ftdi_data_io;
assign ftdi_data_io   = ftdi_oen_o ? ftdi_data_out_w : 8'hZZ;
```

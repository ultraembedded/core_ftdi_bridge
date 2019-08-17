#!/usr/bin/env python
import sys
import argparse

from bus_interface import *

##################################################################
# Main
##################################################################
def main(argv):
    
    parser = argparse.ArgumentParser()
    parser.add_argument('-t', dest='type',   default='ftdi',                  help='Device type (ftdi_async|ftdi)')
    parser.add_argument('-d', dest='device', default='',                      help='Device ID serial.iface_id (e.g. FT3XO4LY.1 or FT3XO4LY.0)')
    parser.add_argument('-a', dest='address',required=True,                   help='Address to write')
    parser.add_argument('-v', dest='value',  required=True,                   help='Value to write')
    args = parser.parse_args()

    bus_if = BusInterface(args.type, args.device)

    addr   = int(args.address, 0)
    value  = int(args.value, 0)

    bus_if.write32(addr, value)

if __name__ == "__main__":
   main(sys.argv[1:])

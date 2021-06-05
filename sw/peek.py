#!/usr/bin/env python
import sys
import argparse

from bus_interface import *

##################################################################
# Main
##################################################################
def main(argv):
    
    parser = argparse.ArgumentParser()
    parser.add_argument('-t', dest='type',   default='ftdi',                     help='Device type (ftdi_async|ftdi)')
    parser.add_argument('-d', dest='device', default='',                         help='Device ID serial.iface_id (e.g. FT3XO4LY.1 or FT3XO4LY.0)')
    parser.add_argument('-a', dest='address',required=True,                      help='Address to read')
    parser.add_argument('-q', dest='quiet',  action='store_true', default=False, help='Quiet mode - set exit code to read value')
    args = parser.parse_args()

    bus_if = BusInterface(args.type, args.device)

    addr   = int(args.address, 0)
    value  = bus_if.read32(addr)

    if not args.quiet:
        print("%08x: 0x%08x (%d)" % (addr, value, value))
    else:
        sys.exit(value)

if __name__ == "__main__":
   main(sys.argv[1:])
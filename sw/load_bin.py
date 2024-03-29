#!/usr/bin/env python
import sys
import argparse

from bus_interface import *

##################################################################
# Print iterations progress
##################################################################
def print_progress(iteration, total, prefix='', suffix='', decimals=1, bar_length=50):
    str_format = "{0:." + str(decimals) + "f}"
    percents = str_format.format(100 * (iteration / float(total)))
    filled_length = int(round(bar_length * iteration / float(total)))
    bar = 'X' * filled_length + ' ' * (bar_length - filled_length)

    sys.stdout.write('\r%s |%s| %s%s %s' % (prefix, bar, percents, '%', suffix)),

    if iteration == total:
        sys.stdout.write('\n')
    sys.stdout.flush()

##################################################################
# Main
##################################################################
def main(argv):
    
    parser = argparse.ArgumentParser()
    parser.add_argument('-t', dest='type',   default='ftdi',                      help='Device type (ftdi_async|ftdi)')
    parser.add_argument('-d', dest='device', default='',                          help='Device ID serial.iface_id (e.g. FT3XO4LY.1 or FT3XO4LY.0)')
    parser.add_argument('-f', dest='filename',required=True,                      help='File to load')
    parser.add_argument('-a', dest='address', default="0",                        help='Address to write to (default to 0x0)')
    parser.add_argument('-s', dest='size',    default=-1,            type=int,    help='Size override')
    parser.add_argument('-v', dest='verify',  default=False, action='store_true', help='Verify write')
    args = parser.parse_args()

    bus_if = BusInterface(args.type, args.device)
    bus_if.set_progress_cb(print_progress)

    # Open file
    file     = open(args.filename, mode='rb')
    data     = file.read()
    filesize = len(data)

    # Size override
    if args.size != -1 and filesize > args.size:
        filesize = args.size

    addr   = int(args.address, 0)
    print("Load: %d bytes to 0x%08x" % (filesize, addr))

    # Write to target
    bus_if.write(addr, data, filesize)

    # Verification
    if args.verify:
        print("Verify:")
        data_rb = bus_if.read(addr, filesize)

        for i in range(filesize):
            if sys.version_info[0] < 3:
                exp = ord(data[i]) & 0xFF
            else:
                exp = data[i] & 0xFF

            if data_rb[i] != exp:
                print("Data mismatches @ %d: %s != %d" % (addr + i,  str(data_rb[i]), exp))
                sys.exit(-1)

        print("Verify: Done")

if __name__ == "__main__":
   main(sys.argv[1:])


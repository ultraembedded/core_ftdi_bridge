from pylibftdi import Device, Driver

##################################################################
# FtdiAsyncInterface: FTDI Async FIFO -> Bus master interface
##################################################################
class FtdiAsyncInterface:
    ##################################################################
    # Construction
    ##################################################################
    def __init__(self, iface = None):
        self.interface  = iface
        self.target     = None
        self.prog_cb    = None
        self.CMD_NOP    = 0x0
        self.CMD_WR     = 0x1
        self.CMD_RD     = 0x2
        self.CMD_GP_WR  = 0x3
        self.CMD_GP_RD  = 0x4
        self.HDR_SIZE   = 6
        self.MAX_SIZE   = 255
        self.BLOCK_SIZE_WR = 16 # Really 2048
        self.BLOCK_SIZE_RD = 32
        self.MAGIC_ADDR = 0xF0000000

        # Default
        self.dev_id     = None
        self.dev_iface  = 2

        # User specified (device_id.iface)
        if iface != None and iface != "":
            parts = iface.split(".")
            self.dev_id = parts[0]
            if len(parts) > 1:
                self.dev_iface  = int(parts[1])

    ##################################################################
    # set_progress_cb: Set progress callback
    ##################################################################
    def set_progress_cb(self, prog_cb):
        self.prog_cb    = prog_cb

    ##################################################################
    # connect: Open serial connection
    ##################################################################
    def connect(self):
        self.target = Device(device_id=self.dev_id,interface_select=self.dev_iface)

    ##################################################################
    # write: Write a block of data to a specified address
    ##################################################################
    def write(self, addr, data, length, addr_incr=True, max_block_size=-1):
        # Connect if required
        if self.target == None:
            self.connect()

        # Write blocks
        idx       = 0
        remainder = length

        if self.prog_cb != None:
            self.prog_cb(0, length)

        if max_block_size == -1:
            max_block_size = self.BLOCK_SIZE_WR

        while remainder > 0:
            l = max_block_size
            if l > remainder:
                l = remainder

            cmd = bytearray(2 + 4 + l)
            cmd[0] = (((l >> 8) & 0xF) << 4) | self.CMD_WR
            cmd[1] = l & 0xFF
            cmd[2] = (addr >> 24) & 0xFF
            cmd[3] = (addr >> 16) & 0xFF
            cmd[4] = (addr >> 8)  & 0xFF
            cmd[5] = (addr >> 0)  & 0xFF

            for i in range(l):
                cmd[6+i] = data[idx]
                idx += 1

            # Write to interface
            self.target.write(cmd)

            # Update display
            if self.prog_cb != None:
                self.prog_cb(idx, length)

            if addr_incr:
                addr  += l
            remainder -= l

    ##################################################################
    # read: Read a block of data from a specified address
    ##################################################################
    def read(self, addr, length, addr_incr=True, max_block_size=-1):
        # Connect if required
        if self.target == None:
            self.connect()

        idx       = 0
        remainder = length
        data      = bytearray(length)

        if self.prog_cb != None:
            self.prog_cb(0, length)

        if max_block_size == -1:
            max_block_size = self.BLOCK_SIZE_RD

        while remainder > 0:
            l = max_block_size
            if l > remainder:
                l = remainder

            cmd = bytearray(2 + 4)
            cmd[0] = (((l >> 8) & 0xF) << 4) | self.CMD_RD
            cmd[1] = l & 0xFF
            cmd[2] = (addr >> 24) & 0xFF
            cmd[3] = (addr >> 16) & 0xFF
            cmd[4] = (addr >> 8)  & 0xFF
            cmd[5] = (addr >> 0)  & 0xFF

            # Write to serial port
            self.target.write(cmd)

            # Read block response
            for i in range(l):
                data[idx] = ord(self.target.read(1)) & 0xFF
                idx += 1

            # Update display
            if self.prog_cb != None:
                self.prog_cb(idx, length)

            if addr_incr:
                addr      += l
            remainder -= l

        return data

    ##################################################################
    # read32: Read a word from a specified address
    ##################################################################
    def read32(self, addr):
        # Connect if required
        if self.target == None:
            self.connect()

        #if addr == self.MAGIC_ADDR:
        #    return self.read_gpio()

        # Send read command
        cmd = bytearray([self.CMD_RD, 
                         4, 
                        (addr >> 24) & 0xFF, 
                        (addr >> 16) & 0xFF, 
                        (addr >> 8) & 0xFF, 
                        (addr >> 0) & 0xFF])
        self.target.write(cmd)

        value = 0
        idx   = 0
        while (idx < 4):
            b = self.target.read(1)
            value |= (ord(b) << (idx * 8))
            idx += 1

        return value

    ##################################################################
    # write32: Write a word to a specified address
    ##################################################################
    def write32(self, addr, value):
        # Connect if required
        if self.target == None:
            self.connect()

        #if addr == self.MAGIC_ADDR:
        #    self.write_gpio(value)
        #    return

        # Send write command
        cmd = bytearray([self.CMD_WR,
                         4, 
                        (addr >> 24)  & 0xFF, 
                        (addr >> 16)  & 0xFF, 
                        (addr >> 8)   & 0xFF, 
                        (addr >> 0)   & 0xFF, 
                        (value >> 0)  & 0xFF, 
                        (value >> 8)  & 0xFF, 
                        (value >> 16) & 0xFF, 
                        (value >> 24) & 0xFF])
        self.target.write(cmd)

  
    ##################################################################
    # read_gpio: Read GPIO bus
    ##################################################################
    def read_gpio(self):
        # Connect if required
        if self.target == None:
            self.connect()

        # Send read command
        cmd = bytearray([self.CMD_GP_RD])
        self.target.write(cmd)

        return ord(self.target.read(1))

    ##################################################################
    # write_gpio: Write a byte to GPIO
    ##################################################################
    def write_gpio(self, value):
        # Connect if required
        if self.target == None:
            self.connect()

        # Send write command
        cmd = bytearray([self.CMD_GP_WR,
                         (value >> 0)  & 0xFF])
        self.target.write(cmd)

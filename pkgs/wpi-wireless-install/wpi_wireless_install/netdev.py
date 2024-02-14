from socket import socket, AF_INET, SOCK_DGRAM
from fcntl import ioctl
from memutils import int_val, ptr_val, cstr_val

"""

Internals:
==========

#define SIOCETHTOOL     0x8946  /* IOCTL opcode */
#define GPERMADDR       0x0020  /* Get permanent hardware address */
#define IFNAMSIZ        16      /* Interface name (max) size */

/* IOCTL argument */
struct ifreq {
    char    ifr_name[IFNAMSIZ]; /* Interface name */
    char   *ifr_data;           /* Pointer to actual (raw) ioctl command (struct perm_addr) */
};

/* IOCTL argument */
struct perm_addr {
    __u32   cmd;                /* Command opcode (GPERMADDR) */
    __u32   size;               /* Size of result value buffer, typically set to 32 */
    __u8    data[0];            /* Result */
};

"""

SIOCETHTOOL = 0x8946
GPERMADDR   = 0x0020
IFNAMSIZ    = 16

class PermanentAddressIORequest(object):
    OUTPUT_BUFFER_SIZE = 32

    def __init__(self, devname):
        cmd = int_val(GPERMADDR)
        size = int_val(self.OUTPUT_BUFFER_SIZE)
        data = cstr_val(self.OUTPUT_BUFFER_SIZE)
        self.reqbuffer = bytearray(cmd + size + data)

        ifr_name = cstr_val(IFNAMSIZ, devname)
        ifr_data = ptr_val(self.reqbuffer)
        self.raw = bytes(ifr_name + ifr_data)

    def raw_result(self):
        return self.reqbuffer[len(self.reqbuffer)-self.OUTPUT_BUFFER_SIZE:]

    def address(self, seperator=':'):
        result = self.raw_result()
        if result[0] != 0 or result[6] == 0:
            return seperator.join([ '%02x' % i for i in result[:6] ])

def get_real_hwaddress(devname):
    s = socket(AF_INET, SOCK_DGRAM)
    fd = s.fileno()
    req = PermanentAddressIORequest(devname)
    ioctl(fd, SIOCETHTOOL, req.raw)
    return req.address()

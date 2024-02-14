from ctypes import string_at
from sys import getsizeof

def _detect_type_sizes():
    POSSIBILITIES = [
        (4, 0),      # x86
        (8, 0),      # amd64
        (4, 2 * 4),  # Same, with debug
        (8, 2 * 8),
    ]

    objhdr_size = getsizeof(None)
    byteshdr_size = getsizeof(b'') & 0xfff8

    for p in POSSIBILITIES:
        native_size, debughdr_size = p
        if objhdr_size == debughdr_size + 2 * native_size and byteshdr_size == objhdr_size + 2 * native_size:
            return p
    return None, None

def _assert_typesize_detected():
    if native_size == None:
        raise Exception('Unable to properly detect length of native variable types (detected: %d, %d)' % (getsizeof(None), getsizeof(b'')))

def get_bytearray_data(header):
    _assert_typesize_detected()
    return read_ptr(header[bytearray_hdr_offset:])[0]

def int_val(val, size=4):
    retval = bytearray()
    exp = 0
    while exp < size:
        retval.append((val >> (exp * 8)) & 0xff)
        exp += 1
    return retval

def cstr_val(size, val=''):
    if type(val) not in [ bytes, bytearray ]:
        val = val.encode('utf-8')
    return (val + b'\0' * size)[0:size]

def ptr_val(ptr=0):
    _assert_typesize_detected()
    if type(ptr) == bytearray:
        ptr = get_bytearray_data(raw(ptr))
    return int_val(ptr, size=ptr_size)

def read_ptr(addr, readsize=0):
    _assert_typesize_detected()
    if type(addr) == int:
        addr = string_at(addr, ptr_size)
    pos = 0
    retval = 0
    while pos < ptr_size:
        v = addr[pos]
        if type(v) == str:
            v = ord(v)
        retval += v << (pos * 8)
        pos += 1
    return retval, (None if readsize == 0 else string_at(retval, readsize))

def deref(pointer, readsize):
    return read_ptr(pointer, readsize)[1]

def read_ptr_pretty(addr):
    _assert_typesize_detected()
    return ('0x%0' + str(ptr_size * 2) + 'x') % read_ptr(addr)[0]

def raw(object):
    return string_at(id(object), getsizeof(object))


native_size, debug_hdr_size = _detect_type_sizes()
if native_size != None:
    int_size = 4
    long_size = native_size
    ptr_size = native_size
    bytearray_hdr_offset = debug_hdr_size + 5 * native_size

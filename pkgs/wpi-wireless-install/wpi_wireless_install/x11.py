from ctypes import cast, CDLL, POINTER
from ctypes import c_void_p, c_char_p, c_int, c_uint, c_long, c_ulong
from struct import pack

from detect import detect_library, LibraryNotFoundError
from memutils import int_size, long_size, ptr_size

class X_Atom(c_ulong):
    pass

class X_Bool(c_int):
    pass

class X_Display_p(c_void_p):
    OFFSET_DEFAULT_SCREEN = 14 * ptr_size + 14 * int_size + 5 * long_size + 4 * (long_size - int_size)
    OFFSET_SCREENS = OFFSET_DEFAULT_SCREEN + 2 * int_size

    def default_screen_nr(self):
        return cast(c_void_p(self.value + self.OFFSET_DEFAULT_SCREEN), POINTER(c_int))[0]

    def screens(self):
        return X_Screen_p(self.value + self.OFFSET_SCREENS)

    def screen(self, idx=0):
        return X_Screen_p(self.screens().value + X_Screen_p.SIZE * idx)

    def default_screen(self):
        return self.screen(self.default_screen_nr())

class X_Screen_p(c_void_p):
    SIZE = 5 * ptr_size + 5 * long_size + 10 * int_size + 2 * (long_size - int_size)

    OFFSET_ROOT_WINDOW = 2 * ptr_size

    def root_window(self):
        return X_Window(cast(c_void_p(self.value + self.OFFSET_ROOT_WINDOW), c_long)[0])

class X_Status(c_int):
    pass

class X_XID(c_ulong):
    pass

class X_Window(X_XID):
    pass

class X_XEvent_p(c_void_p):
    pass

try:
    Xlib = detect_library('libX11.so')

    Xlib.XOpenDisplay.argtypes = [ c_char_p ]
    Xlib.XOpenDisplay.restype = X_Display_p
    Xlib.XCloseDisplay.argtypes = [ X_Display_p ]
    Xlib.XCloseDisplay.restype = int
    Xlib.XInternAtom.argtypes = [ X_Display_p, c_char_p, X_Bool ]
    Xlib.XInternAtom.restype = X_Atom
    Xlib.XSendEvent.argtypes = [ X_Display_p, X_Window, X_Bool, c_long, X_XEvent_p ]
    Xlib.XSendEvent.restype = X_Status
    Xlib.XIconifyWindow.argtypes = [ X_Display_p, X_Window, c_int ]
    Xlib.XIconifyWindow.restype = X_Status

except LibraryNotFoundError:
    raise ImportError('Cannot import module x11: opening libX11.so failed')


class WindowManager(object):
    XCB_EWMH_WM_STATE_REMOVE = 0
    XCB_EWMH_WM_STATE_ADD = 1
    XCB_EWMH_WM_STATE_TOGGLE = 2

    ClientMessage = 33

    SubstructureNotifyMask = 0x80000
    SubstructureRedirectMask = 0x100000

    MESSAGE_FORMAT  = 'i'                                       # int type;
    MESSAGE_FORMAT += 'xxxxQ' if long_size == 8 else 'L'        # unsigned long serial;
    MESSAGE_FORMAT += 'i'                                       # Bool send_event;
    MESSAGE_FORMAT += 'xxxxq' if ptr_size  == 8 else 'l'        # Display *display;
    MESSAGE_FORMAT += 'Q'     if long_size == 8 else 'L'        # Window window;
    MESSAGE_FORMAT += 'Q'     if long_size == 8 else 'L'        # Atom message_type;
    MESSAGE_FORMAT += 'i'                                       # int format;
    MESSAGE_FORMAT += 'xxxx'  if long_size == 8 else ''
    MESSAGE_FORMAT += 'qqqqq' if long_size == 8 else 'lllll'    # long data[5]

    def __init__(self):
        self.display = Xlib.XOpenDisplay(None)
        self.atoms = {}
        self._serial = -1

    def __del__(self):
        Xlib.XCloseDisplay(self.display)

    def serial(self):
        self._serial += 1
        return self._serial

    def get_x11_atom(self, atom):
        if not atom in self.atoms:
            self.atoms[atom] = Xlib.XInternAtom(self.display, atom, 0)
        return self.atoms[atom]

    def send_x11_message(self, window, msgtype, *params):
        params = (list(params) + [ 0, 0, 0, 0, 0 ])[:5]
        data = pack(self.MESSAGE_FORMAT, self.ClientMessage, self.serial(), int(True), 0, window, self.get_x11_atom(msgtype), 32, *params)
        mask = self.SubstructureRedirectMask | self.SubstructureNotifyMask;
        return bool(Xlib.XSendEvent(self.display, self.root_window(), 0, mask, data))

    def root_window(self):
        return self.display.default_screen().root_window()

    def add_window_state(self, window, *states):
        return self.send_x11_message(int(window), '_NET_WM_STATE', self.XCB_EWMH_WM_STATE_ADD, *[ self.get_x11_atom(s) for s in states[:2] ])

    def remove_window_state(self, window, *states):
        return self.send_x11_message(int(window), '_NET_WM_STATE', self.XCB_EWMH_WM_STATE_REMOVE, *[ self.get_x11_atom(s) for s in states[:2] ])

    def toggle_window_state(self, window, *states):
        return self.send_x11_message(int(window), '_NET_WM_STATE', self.XCB_EWMH_WM_STATE_TOGGLE, *[ self.get_x11_atom(s) for s in states[:2] ])

    def minimize(self, window):
        return Xlib.XIconifyWindow(self.display, int(window), self.display.default_screen_nr())

    def unminimize(self, window):
        return self.remove_window_state(window, '_NET_WM_STATE_HIDDEN') # FIXME

    def maximize(self, window):
        return self.add_window_state(window, '_NET_WM_STATE_MAXIMIZED_HORZ', '_NET_WM_STATE_MAXIMIZED_VERT')

    def unmaximize(self, window):
        return self.remove_window_state(window, '_NET_WM_STATE_MAXIMIZED_HORZ', '_NET_WM_STATE_MAXIMIZED_VERT')

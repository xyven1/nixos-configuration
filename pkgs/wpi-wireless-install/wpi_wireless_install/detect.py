from ctypes import CDLL
from fnmatch import fnmatch
from os import access, listdir, path, walk, X_OK, getenv
from subprocess import check_call, Popen, CalledProcessError, PIPE, STDOUT

VERBOSE_DETECT = False

# get dirs from $PATH
BIN_DIRS = getenv('PATH').split(":")
LIB_DIRS = [ '/lib', '/usr/local/lib', '/usr/lib', '/usr/lib/x86_64-pc-linux-gnu', '/usr/lib/x86_64-linux-gnu', '/usr/lib/i686-pc-linux-gnu', '/usr/lib/i686-linux-gnu', '/usr/lib/i386-pc-linux-gnu', '/usr/lib/i386-linux-gnu' ]


class ExecutableNotFoundError(Exception):
    pass

class LibraryNotFoundError(Exception):
    pass

class ExternalExecutionError(Exception):
    pass

class Executable(object):
    def __init__(self, path):
        self.path = path

    def run(self, *args, **kwargs):
        args = list(args)
        background = False if 'background' not in kwargs else kwargs['background']
        try:
            if not background:
                check_call([ self.path ] + args)
            else:
                Popen([ self.path ] + args)
        except CalledProcessError as e:
            raise ExternalExecutionError('Failed to invoke %s with arguments %s: %s' % (self, str(args), str(e)))

    def run_silent(self, *args, **kwargs):
        args = list(args)
        background = False if 'background' not in kwargs else kwargs['background']
        try:
            with open('/dev/null', 'w') as devnull:
                if not background:
                    check_call([ self.path ] + args, stdout=devnull, stderr=devnull)
                else:
                    Popen([ self.path ] + args, stdout=devnull, stderr=devnull)
        except CalledProcessError as e:
            raise ExternalExecutionError('Failed to invoke %s with arguments %s: %s' % (self, str(args), str(e)))

    def run_and_get_output(self, *args, **kwargs):
        accept_returncodes = kwargs['accept_returncodes'] if 'accept_returncodes' in kwargs else [ 0 ]
        args = list(args)
        ps = Popen([ self.path ] + args, shell=False, stdout=PIPE, stderr=STDOUT)
        output = ps.communicate()[0].decode('utf-8')
        if accept_returncodes != None and not ps.returncode in accept_returncodes:
            raise ExternalExecutionError('Failed to invoke %s with arguments %s: process exited with code %d\nOutput:\n%s' % (self, str(args), ps.returncode, output))
        return output

    def __str__(self):
        return self.path

def detect_executable(name):
    for dir in BIN_DIRS:
        exepath = path.join(dir, name)
        if path.isfile(exepath) and access(exepath, X_OK):
            return Executable(exepath)
    if VERBOSE_DETECT:
        print('detect_executable(): Could not locate "%s" in %s' % (name, ', '.join(dirs)))
    raise ExecutableNotFoundError(name)

def detect_library(basename, dirs=None):
    if dirs is None:
        dirs = LIB_DIRS

    if basename[len(basename)-3:] != '.so':
        basename += '.so'
    for dir in dirs:
        try:
            file = next(iter(filter(lambda f: f[:len(basename)] == basename and path.isfile(path.join(dir, f)), next(walk(dir))[2])))
        except StopIteration:
            continue
        try:
            fullpath = path.join(dir, file)
            native_lib = CDLL(fullpath)

            if VERBOSE_DETECT:
                print('detect_library(): Loaded %s.' % fullpath)

            return native_lib
        except OSError as e:
            if VERBOSE_DETECT:
                print('detect_library(): Could not open located library "%s": %s, ignoring...' % (fullpath, str(e)))
    if VERBOSE_DETECT:
        print('detect_library(): Could not locate "%s" in %s' % (basename, ', '.join(dirs)))
    raise LibraryNotFoundError(basename)

def wpa_supplicant_version():
    try:
        wpa_supplicant = detect_executable('wpa_supplicant')
    except ExecutableNotFoundError:
        return 0.0

    version_string = wpa_supplicant.run_and_get_output('-v').split('\n')[0]
    prefix = 'wpa_supplicant v'

    if version_string[0:len(prefix)] != prefix:
        return 0.0

    try:
        return float(version_string[len(prefix):].split(' ')[0].split('-')[0])
    except ValueError:
        return 0.0


try:
    arch = detect_executable('uname').run_and_get_output('-m').split('\n')[0]
except (ExecutableNotFoundError|ExternalExecutionError|OSError):
    arch = 'x86_64'

arch_bits = '64' if '64' in arch else '32'


def _read_library_dirs(filename = '/etc/ld.so.conf'):
    with open(filename, 'r') as file:
        for dir in filter(lambda line: len(line) > 0 and line[0] != '#', [ line.lstrip() for line in file.read().split('\n') ]):
            if dir.split()[0] == 'include':
                include_path = dir.split()[-1]
                include_path = path.join(path.dirname(filename), include_path) if include_path[0] != '/' else include_path
                if '*' not in include_path:
                    for dir in _read_library_dirs(include_path):
                        yield dir
                elif '*' not in path.dirname(include_path):
                    files_wildcard = path.basename(include_path)
                    for include_filename in filter(lambda fn: fnmatch(fn, files_wildcard), listdir(path.dirname(include_path))):
                        for dir in _read_library_dirs(path.join(path.dirname(include_path), include_filename)):
                            yield dir
                else:
                    pass    # Wildcard directory matching not supported
            else:
                yield dir

try:
    _detected_dirs = list(_read_library_dirs())
    _includes_default_lib_dirs = '/usr/lib' in _detected_dirs or '/usr/lib' + arch_bits in _detected_dirs

    LIB_DIRS = LIB_DIRS + [ p + arch_bits for p in LIB_DIRS ] + _detected_dirs if not _includes_default_lib_dirs else _detected_dirs

except IOError:
    LIB_DIRS += [ p + arch_bits for p in LIB_DIRS ]
    LIB_DIRS += [ path.join(p, arch + '-pc-linux-gnu') for p in LIB_DIRS ] + \
                [ path.join(p, arch + '-linux-gnu') for p in LIB_DIRS ] + \
                [ '/usr/' + arch + '-pc-linux-gnu/lib', '/usr/' + arch + '-pc-linux-gnu/lib' ] + \
                [ '/usr/' + arch + '-pc-linux-gnu/lib' + arch_bits, '/usr/' + arch + '-pc-linux-gnu/lib' + arch_bits ]


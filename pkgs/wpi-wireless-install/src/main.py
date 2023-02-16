#!/usr/bin/python

import os
import sys
import subprocess
from subprocess import Popen, PIPE, STDOUT, CalledProcessError

INTERPRETER_AUTODETECTION_FLAG = '--interpreter-detect'
INTERPRETER_AUTODETECTION_VERBOSE_FLAG = '--verbose-detect'
EXECUTABLE_AUTODETECTION_VERSION_FLAG = '--verbose-detect-external'
ALL_AUTODETECTION_VERSION_FLAG = '--verbose-detect-all'
EXCEPTION_BACKTRACE_FLAG = '--backtrace'
ALL_EXCEPTIONS_BACKTRACE_FLAG = '--backtrace-all'

#
#  Work-around for certain libraries not being available
#  for all installed python versions on some distros
#
def valid_interpreter(path):
    exebasename = os.path.basename(path)
    return  exebasename.startswith('python') and \
            (len(exebasename) == 6 or exebasename[6] in ['2', '3' ]) and \
            not '-' in exebasename and \
            os.path.isfile(path) and \
            os.access(path, os.X_OK)

def safe_listdir(path):
    try:
        return os.listdir(path)
    except OSError:
        return []

def find_all_interpreters():
    return sorted(filter(lambda e: valid_interpreter(e), [ path + os.path.sep + filename for path in os.environ['PATH'].split(os.pathsep) for filename in safe_listdir(path) ]))

autodetecting = INTERPRETER_AUTODETECTION_FLAG in sys.argv

try:
    import logger
    from logger import ConsoleLogger, FileLogger
    from client import PaladinLinuxClient

except ImportError as e:
    if autodetecting:
        raise
    with open(os.devnull, 'w') as devnull:
        stdout = devnull if not INTERPRETER_AUTODETECTION_VERBOSE_FLAG in sys.argv and not ALL_AUTODETECTION_VERSION_FLAG in sys.argv else None
        for interpreter in find_all_interpreters():
            args = [ interpreter, os.path.abspath(sys.argv[0]) ] + sys.argv[1:]
            try:
                subprocess.check_call(args + [ INTERPRETER_AUTODETECTION_FLAG ], stdout=stdout, stderr=STDOUT)
            except CalledProcessError:
                continue
            if INTERPRETER_AUTODETECTION_VERBOSE_FLAG in sys.argv or ALL_AUTODETECTION_VERSION_FLAG in sys.argv:
                print('Re-launching using command line: ' + ' '.join(args))
            os.execv(args[0], args)
    print('Error: One or more required python libraries have not been installed: ' + str(e))
    sys.exit(1)

if not autodetecting:
    logger.register(ConsoleLogger())
    logger.register(FileLogger())

    if EXECUTABLE_AUTODETECTION_VERSION_FLAG in sys.argv or ALL_AUTODETECTION_VERSION_FLAG in sys.argv:
        import detect
        detect.VERBOSE_DETECT = True

    try:
        PaladinLinuxClient().run(mask_exceptions=(not EXCEPTION_BACKTRACE_FLAG in sys.argv and not ALL_EXCEPTIONS_BACKTRACE_FLAG in sys.argv), handle_errors=(not ALL_EXCEPTIONS_BACKTRACE_FLAG in sys.argv))
    except KeyboardInterrupt as e:
        print('')
        sys.exit(1)
    finally:
        logger.shutdown()

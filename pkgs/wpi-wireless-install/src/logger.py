import inspect
import logging

CONSOLELOGGER_LEVEL = logging.INFO
CONSOLELOGGER_FORMAT = '%(asctime)s - %(message)s'

FILELOGGER_LEVEL = logging.DEBUG
FILELOGGER_FORMAT = '%(asctime)s - %(lineno)d - %(levelname)-8s - %(message)s'
FILELOGGER_FILENAME = '/tmp/securew2_joinnow.log'

registered_loggers = []

class Logger(object):
    def __init__(self, level, format):
        self.level = level
        self.format = format

    def configure_handler(self, handler):
        handler.setLevel(self.level)
        handler.setFormatter(logging.Formatter(self.format))
        return handler

class FileLogger(Logger):
    def __init__(self, level=FILELOGGER_LEVEL, filename=FILELOGGER_FILENAME, format=FILELOGGER_FORMAT):
        super(FileLogger, self).__init__(level, format)
        self.filename = filename

    def get_handler(self):
        return self.configure_handler(logging.FileHandler(self.filename, mode='w'))

class ConsoleLogger(Logger):
    def __init__(self, level=CONSOLELOGGER_LEVEL, format=CONSOLELOGGER_FORMAT):
        super(ConsoleLogger, self).__init__(level, format)

    def get_handler(self):
        return self.configure_handler(logging.StreamHandler())

def register(logger):
    global registered_loggers
    registered_loggers += [ logger ]

def function_logger():
    function_name = inspect.stack()[1][3]
    logger = logging.getLogger(function_name)
    logger.setLevel(logging.DEBUG)

    for handler in [ l.get_handler() for l in registered_loggers ]:
        logger.addHandler(handler)

    return logger

def shutdown():
    global registered_loggers
    registered_loggers = []
    logging.shutdown()

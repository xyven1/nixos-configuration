from getpass import getpass as _getpass

from pycompat import _raw_input as __raw_input

_ui = None


def unicode_encoding_workaround(func):
    def wrapper(prompt):
        try:
            return func(prompt)
        except UnicodeEncodeError:
            # Work-around for python 2.x getpass() not able to handle utf-8 encoding
            # Note, we can't use 'print x,' syntax here
            import codecs
            with codecs.open('/dev/tty', 'w', 'utf-8') as out:
                out.write(prompt)
            return func('')
    return wrapper

@unicode_encoding_workaround
def getpass(prompt):
    return _getpass(prompt)


@unicode_encoding_workaround
def _raw_input(prompt):
    return __raw_input(prompt)


class Buttons:
    NEXT = 14
    SKIP = 15
    CONTINUE = 16
    CANCEL = 17
    DONE = 18
    RETRY = 19

class Window(object):
    class Message(object):
        def __init__(self, text):
            self.text = text

    class Prompt(object):
        def __init__(self, text, secret, verify_callback, result_key):
            self.text = text
            self.secret = secret
            self.result_key = result_key
            if verify_callback != None:
                self.verify_callback = verify_callback[0]
                self.verify_callback_data = verify_callback[1] if len(verify_callback) > 1 else None
            else:
                self.verify_callback = None

    def __init__(self, parent, title):
        self.parent = parent
        self.title = title
        self.components = []
        self.results = {}

    def add_message(self, text):
        text = self.parent.to_string(text)
        self.components += [ Window.Message(text) ]

    def add_prompt(self, text, secret=False, verify_callback=None, result_key=None):
        text = self.parent.to_string(text)
        self.components += [ Window.Prompt(text, secret, verify_callback, result_key) ]

    def get_result(self, key):
        key = self.parent.to_string(key)
        return self.results[key] if key in self.results else None


class UI(object):
    def __init__(self, resources):
        self.resources = resources
        self.status = None
        self.current_action = None

    def enter_action(self, action):
        self.current_action = action

    def leave_action(self):
        self.current_action = None

    def to_string(self, text, resources=None):
        if type(text) == int:
            return (resources if resources != None else self.current_action.resources if self.current_action != None else self.resources).get_string(text)
        return text

    def update_status(self, new_status, resources=None):
        new_status = self.to_string(new_status, resources)
        if new_status != self.status:
            self.status = new_status
            self.draw_status_screen(self.status)

    def show_message(self, message, title=35, buttons=[Buttons.NEXT]):
        message = self.to_string(message)
        title = self.to_string(title)
        self.draw_message_window(title, message, buttons)
        return self.get_window_result(buttons)

    def window(self, title=35):
        return Window(self, title)


class ConsoleUI(UI):
    def __init__(self, resources):
        super(ConsoleUI, self).__init__(resources)
        self.window_is_message = False

    def draw_status_screen(self, status):
        if self.window_is_message:
            print('')
            self.window_is_message = False
        print(status)

    def draw_message_window(self, title, message, buttons):
        self.window_is_message = True
        print('')
        print(message)
        print('')

    def get_window_result(self, buttons):
        return self.select_button(buttons)

    def execute(self, window, buttons=[ Buttons.NEXT ]):
        self.window_is_message = True
        last_component = None
        for component in window.components:
            if isinstance(component, Window.Message):
                print('')
                print(component.text)
            elif isinstance(component, Window.Prompt):
                prompt = (component.text if component.text != None else '>') + ' '
                result_key = component.result_key if component.result_key != None else component.text
                if not isinstance(last_component, Window.Prompt):
                    print('')
                valid_input = False
                while not valid_input:
                    window.results[result_key] = _raw_input(prompt) if not component.secret else getpass(prompt)
                    if component.verify_callback != None:
                        valid_input = component.verify_callback(window.results[result_key], window) if not component.verify_callback_data != None else \
                                      component.verify_callback(component.verify_callback_data, window.results[result_key], window)
                        if type(valid_input) == tuple:
                            if not valid_input[0]:
                                print('')
                                print(self.to_string(valid_input[1]))
                                return self.execute(window, buttons)
                            else:
                                if valid_input[1] != None:
                                    window.results[result_key] = valid_input[1]
                                valid_input = True
                    else:
                        valid_input = True
            last_component = component
        return self.select_button(buttons)

    def select_button(self, buttons):
        if len(buttons) < 2:
            return buttons[0] if len(buttons) > 0 else None
        all_choices = [ self.to_string(b) for b in buttons ]
        possible_choices = []
        default = self.to_string(buttons[0])
        while len(possible_choices) != 1:
            choice = _raw_input('/'.join(all_choices) + '? [' + default + '] ').upper()
            if choice == '':
                choice = default.upper()
            possible_choices = list(filter(lambda b: b[:len(choice)].upper() == choice, all_choices))
        return buttons[all_choices.index(possible_choices[0])]

def detect_ui():
    return ConsoleUI

def ui(resources):
    global _ui
    if _ui == None:
        _ui = detect_ui()(resources)
    return _ui

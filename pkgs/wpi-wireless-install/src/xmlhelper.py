class InvalidCloudConfigException(Exception):
    pass

def get_xml_subnode(xml_node, name):
    if isinstance(xml_node, CloudConfigNodeWrapper):
        xml_node = xml_node.xml_node
    try:
        return xml_node.find(name)
    except AttributeError:
        return None

def get_xml_value(xml_node, name, default=None):
    if isinstance(xml_node, CloudConfigNodeWrapper):
        xml_node = xml_node.xml_node
    try:
        return xml_node.find(name).text
    except AttributeError:
        return default

def get_xml_value_bool(xml_node, name, default=None):
    value = get_xml_value(xml_node, name, default={ None: None, True: 'true', False: 'false' }[default])
    if value == None:
        return None
    value = value.lower()
    try:
        return int(value) != 0
    except ValueError:
        pass
    return value == 'true' or value == 'yes' or value == 'on' or value == 'enable' or value == 'enabled'

def get_xml_value_int(xml_node, name, default=None):
    value = get_xml_value(xml_node, name, default=(None if default == None else str(default)))
    if value == None:
        return None
    return int(value)

class CloudConfigNodeWrapper(object):
    def __init__(self, xml_node, action=None):
        self.xml_node = xml_node
        self.action = action

    def error_context(self):
        if self.action != None:
            return ' while parsing configuration for action %s' % self.action.__class__.__name__
        return ''

    def raise_on_none_if_required(self, value, required, error_text):
        if value != None or not required:
            return value
        raise InvalidCloudConfigException(error_text + self.error_context())

    def node(self, name, required=True):
        return CloudConfigNodeWrapper(self.raise_on_none_if_required(get_xml_subnode(self.xml_node, name), required, 'CloudConfig is missing required node "%s"' % name))

    def findall(self, path, required=False, values=False):
        nodes = [ (CloudConfigNodeWrapper(node) if not values else node.text) for node in self.xml_node.findall(path) ]
        if len(nodes) > 0 or not required:
            return nodes
        raise InvalidCloudConfigException(('CloudConfig is missing required node(s) at "%s"' % path) + self.error_context())

    def value(self, name, default=None, required=True):
        return self.raise_on_none_if_required(get_xml_value(self.xml_node, name, default=default), required, 'CloudConfig is missing required parameter "%s"' % name)

    def bool(self, name, default=None, required=True):
        return self.raise_on_none_if_required(get_xml_value_bool(self.xml_node, name, default=default), required, 'CloudConfig is missing required parameter "%s"' % name)

    def int(self, name, default=None, required=True):
        try:
            return self.raise_on_none_if_required(get_xml_value_int(self.xml_node, name, default=default), required, 'CloudConfig is missing required parameter "%s"' % name)
        except ValueError:
            raise InvalidCloudConfigException(('CloudConfig parameter "%s" has invalid value' % name) + self.error_context())

    def __getattr__(self, name):
        return self.node(name)

    def __getitem__(self, key):
        return self.value(key)

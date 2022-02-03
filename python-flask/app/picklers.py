import pickle

from io import BytesIO

class SafeUnpickler(pickle.Unpickler):

    PICKLE_SAFE = {
        'builtins': set(['globals', 'getattr', 'dict', 'apply']),
    }

    def __init__(self, file):
        super().__init__(file, encoding='utf8')

    def find_class(self, module, name):
        if module not in self.PICKLE_SAFE:
            raise pickle.UnpicklingError('Unsafe module detected during unpickle: {}'.format(module))
        __import__(module)
        mod = sys.modules[module]
        if name not in self.PICKLE_SAFE[module]:
            raise pickle.UnpicklingError('Unsafe module detected during unpickle: {}'.format(name))
        return getattr(mod, name)

class unpickle(object):

    @staticmethod
    def loads(pickle_string):
        return SafeUnpickler(BytesIO(pickle_string)).load()

    @staticmethod
    def load(file):
        return SafeUnpickler(file).load()

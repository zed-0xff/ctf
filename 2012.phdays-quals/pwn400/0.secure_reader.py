import __builtin__
import sys

from inspect import getargs
from sys import _getframe as get_frame
from types import FunctionType, GeneratorType, FrameType

__all__ = ['FileReader']

UNSAFE_BUILTINS = [
    'open', 'file', 'execfile', 'reload', 'input', 'eval', 'type', 'compile'
    ]


UNSAFE_ATTRS = [
    '__globals__', '__closure__'
    ]


ALLOWED_FILES = [
    'log.1', 'log.2', 'log.3'
    ]

def make_secure():
    from ctypes import pythonapi, POINTER, py_object

    get_dict = pythonapi._PyObject_GetDictPtr
    get_dict.restype = POINTER(py_object)
    get_dict.argtypes = [py_object]

    def dictionary_of(ob):
        dptr = get_dict(ob)
        if dptr and dptr.contents:
            return dptr.contents.value

    for attr in UNSAFE_ATTRS:
        del dictionary_of(FunctionType)[attr]

    sys.get_frame_locals = dictionary_of(FrameType)['f_locals'].__get__
    sys.get_type = type
    del dictionary_of(type)['__subclasses__']
    del dictionary_of(GeneratorType)['gi_frame']
    del dictionary_of(FrameType)['f_code']
    del dictionary_of(FrameType)['f_builtins']
    del dictionary_of(FrameType)['f_globals']
    del dictionary_of(GeneratorType)['gi_code']


def remove_builtins():
    for item in UNSAFE_BUILTINS:
        del __builtin__.__dict__[item]
    def null(*args, **kwargs):
        pass
    __builtin__.__import__ = null


make_secure()


def _Namespace(
    tuple=tuple, isinstance=isinstance, FunctionType=FunctionType,
    staticmethod=staticmethod, get_frame=get_frame,
    ):

    __private_data = {}

    def Namespace(*args, **kwargs):

        class NamespaceObject(tuple):
            __slots__ = ()
            class __metaclass__(type):
                def __call__(klass, __getter):
                    for name, obj in __getter:
                        setattr(klass, name, obj)
                    return type.__call__(klass, __getter)
                def __str__(klass):
                    return 'NamespaceContext%s' % (tuple(klass.__dict__.keys()),)
            def __new__(klass, __getter):
                return tuple.__new__(klass, __getter)

        ns_items = [];
        populate = ns_items.append

        if args or kwargs:
            frame = None
            for arg in args:
                kwargs[arg.__name__] = arg
            for name, obj in kwargs.iteritems():
                if isinstance(obj, FunctionType):
                    populate((name, staticmethod(obj)))
                else:
                    populate((name, obj))
        del frame, args, kwargs
        return NamespaceObject(ns_items)
    return Namespace

Namespace = _Namespace()
del _Namespace

_marker = object()

def guard(**spec):

    def __decorator(function):
        if sys.get_type(function) is not FunctionType:
            raise TypeError("Incorrect argument")

        func_args = getargs(function.__code__)[0]
        len_args = len(func_args) - 1

        def __func(*args, **kwargs):
            for i, param in enumerate(args):
                req = spec.get(func_args[i], _marker)
                if req is not _marker and sys.get_type(param) is not req:
                    raise TypeError(
                        "%s has to be %r" % (func_args[i], req)
                        )
            for name, param in kwargs.iteritems():
                if name in spec and sys.get_type(param) is not spec[name]:
                    raise TypeError("%s has to be %r" % (name, spec[name]))
            return function(*args, **kwargs)

        __func.__name__ = function.__name__
        __func.__doc__ = function.__doc__

        return __func

    return __decorator


def _Reader(
    open_file=open,
    type=type,
    TypeError=TypeError,
    Namespace=Namespace,
    ):

    @guard(filename=str)
    def Reader(filename):
       if filename not in ALLOWED_FILES:
           raise ValueError("You can't read that shit!")
       data = open_file(filename).read()
       return data

    return Reader

Reader = _Reader()
remove_builtins()

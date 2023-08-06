import json
import logging
from pprint import pformat

from pathlib import Path
import pprint

# pyright: reportMissingImports=false
from polyscript import xworker


def print_tree(path, prefix="", str=""):
    for item in path.iterdir():
        logging.info(f"{prefix}├── {item.name}")
        if item.is_dir():
            print_tree(item, prefix + "│   ")


def sdump(obj):
    s = ""
    try:
        s = pformat(vars(obj), indent=4)
    except TypeError:
        pass

    if s == "":
        try:
            s = pformat(obj, indent=4)
        except TypeError:
            pass

    if s == "":
        try:
            s = pformat(dict(obj), indent=4)
        except TypeError:
            pass

    return f"{type(obj)}: {s}"


def dump(obj):
    logging.debug(sdump(obj))


# def dump(obj):
#     try:
#         pprint(json.dumps(obj))
#     except:
#         # for attr in dir(obj):
#         #     print("obj.%s = %r" % (attr, getattr(obj, attr)))
#         pprint(dir(obj))


class bcolors:
    HEADER = "\033[95m"
    OKBLUE = "\033[94m"
    OKCYAN = "\033[96m"
    OKGREEN = "\033[92m"
    WARNING = "\033[93m"
    FAIL = "\033[91m"
    ENDC = "\033[0m"
    BOLD = "\033[1m"
    UNDERLINE = "\033[4m"


def display(msg):
    xworker.sync.display(msg)

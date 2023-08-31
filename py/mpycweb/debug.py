import asyncio
import json
import logging
from pprint import pformat

from pathlib import Path
import pprint
import sys

# pyright: reportMissingImports=false
from polyscript import xworker


def display(msg):
    xworker.sync.display(msg)


def displayRaw(msg):
    xworker.sync.displayRaw(msg)


# print(Path.cwd())


def print_tree(path, prefix="", str=""):
    try:
        for item in path.iterdir():
            display(f"{prefix}├── {item.name}")
            if item.is_dir():
                print_tree(item, prefix + "│   ", str)
    except:
        pass


# print_tree(Path("../"))


def sdump(obj):
    s = ""
    if s == "":
        try:
            s = "json: " + pformat(json.dumps(obj), indent=4)
        except:
            pass
    if s == "":
        try:
            s = "vars: " + pformat(vars(obj), indent=4)
        except:
            pass

    if s == "":
        try:
            s = "dict: " + pformat(dict(obj), indent=4)
        except:
            pass

    if s == "":
        try:
            s = "attrs: "

            for attr in dir(obj):
                s += f"obj.%s = %r\n" % (attr, getattr(obj, attr))
        except:
            pass

    if s == "":
        try:
            s = "pformat: " + pformat(obj, indent=4)
        except:
            pass

    return f"type: {type(obj)}: {s}"


def dump(obj):
    logging.debug("-----------------------")
    logging.debug(sdump(obj))
    logging.debug("-----------------------")


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


CRITICAL = logging.CRITICAL
FATAL = logging.FATAL
ERROR = logging.ERROR
WARNING = logging.WARNING
WARN = logging.WARN
NOTSET = logging.NOTSET
INFO = logging.INFO
DEBUG = logging.DEBUG


def set_log_level(level):
    if level == logging.DEBUG:
        format = "[%(asctime)s] {%(name)s:%(lineno)d:%(funcName)s} %(levelname)s %(message)s"
    else:
        format = "%(asctime)s %(message)s"

    logging.basicConfig(
        # force=True, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s", level=logging.DEBUG, stream=sys.stdout
        force=True,
        # format="%(created)f:%(levelname)s:%(pathname)s:%(filename)s:%(funcName)s:%(lineno)s:%(module)s:%(message)s",
        format=format,
        datefmt="%H:%M:%S",
        level=level,
        # level=logging.DEBUG,
        stream=sys.stdout,
    )


# set_log_level(logging.INFO)

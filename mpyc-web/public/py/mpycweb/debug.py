import asyncio
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
            print_tree(item, prefix + "│   ", str)


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
            s = "pformat: " + pformat(obj, indent=4)
        except:
            pass

    if s == "":
        try:
            s = "attrs: "

            for attr in dir(obj):
                s += f"obj.%s = %r\n" % (attr, getattr(obj, attr))
        except:
            pass
    return f"type: {type(obj)}: {s}"


def dump(obj):
    logging.debug("-----------------------")
    logging.debug(sdump(obj))
    logging.debug("-----------------------")


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


def displayRaw(msg):
    xworker.sync.displayRaw(msg)


async def ping():
    while True:
        xworker.sync.log("Python Worker Ping")
        await asyncio.sleep(5)


asyncio.ensure_future(ping())

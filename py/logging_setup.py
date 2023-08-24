import logging
import sys


def set_level(level):
    if level == logging.DEBUG:
        format = "[%(asctime)s] {%(name)s:%(lineno)d:%(funcName)s} %(levelname)s %(message)s"
        datefmt = "%H:%M:%S"
    else:
        format = "%(asctime)s %(message)s"
        datefmt = "%H:%M:%S"

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


set_level(logging.INFO)
# set_level(logging.DEBUG)

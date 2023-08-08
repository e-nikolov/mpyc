import logging
import sys

# level = logging.DEBUG
level = logging.INFO

logging.basicConfig(
    # force=True, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s", level=logging.DEBUG, stream=sys.stdout
    force=True,
    # format="%(created)f:%(levelname)s:%(pathname)s:%(filename)s:%(funcName)s:%(lineno)s:%(module)s:%(message)s",
    format="[%(asctime)s] {%(name)s:%(lineno)d:%(funcName)s} %(levelname)s %(message)s",
    datefmt="%H:%M:%S",
    level=level,
    # level=logging.DEBUG,
    stream=sys.stdout,
)

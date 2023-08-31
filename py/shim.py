# pyright: reportMissingImports=false
import sys
import mpycweb.redirect_stdout
import logging_setup
from mpyc.runtime import mpc
import mpycweb
from mpycweb.debug import *

# TODO fix the WebLoop performance with asyncio.sleep(0) https://github.com/pyodide/pyodide/issues/4006

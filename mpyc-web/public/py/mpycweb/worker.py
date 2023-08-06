## Receiving stuff from the main JS thread
import asyncio
import json
import logging
from typing import Callable, Any

from mpyc.runtime import mpc

# pyright: reportMissingImports=false
from polyscript import xworker

from .debug import *

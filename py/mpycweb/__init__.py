from asyncio import Future, Task
import time
import types
from typing import Coroutine

from .debug import *

from .transport import *
from .worker import *
from .patches import *
from . import peerjs
from mpyc.runtime import mpc, Runtime

# pyright: reportMissingImports=false
from polyscript import xworker

# TODO refactor to fire an event instead of printing
display("PyScript runtime started.")

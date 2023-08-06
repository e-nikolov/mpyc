import logging
from typing import Any, Coroutine
import logging_setup

import sys
import time

from pathlib import Path


import secretsanta as secretsanta
from mpyc import asyncoro
from mpyc.runtime import mpc, Party

# pyright: reportMissingImports=false
from polyscript import xworker
import demos.secretsanta
import asyncio

import mpycweb
from mpycweb import bcolors, display, print_tree


async def xprint(N, text, sectype) -> None:
    display(f"{bcolors.UNDERLINE}{bcolors.WARNING}Using secure {text}: {sectype.__name__}{bcolors.ENDC}{bcolors.ENDC}")
    for n in range(2, N + 1):
        display(f"{bcolors.OKBLUE}{n} {await mpc.output(secretsanta.random_derangement(n, sectype))}{bcolors.ENDC}")


demos.secretsanta.xprint = xprint
mpc.run(secretsanta.main())

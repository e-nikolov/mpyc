import mpycweb.redirect_stdout
import contextlib
import io
import logging
from typing import Any, Coroutine
import logging_setup

import sys
import time

from pathlib import Path


from mpyc import asyncoro
from mpyc.runtime import mpc, Party

# pyright: reportMissingImports=false
from polyscript import xworker
import demos.secretsanta
import demos.oneliners
import asyncio

import mpycweb
from mpycweb import bcolors, display, print_tree


async def xprint(N, text, sectype) -> None:
    display(f"{bcolors.UNDERLINE}{bcolors.WARNING}Using secure {text}: {sectype.__name__}{bcolors.ENDC}{bcolors.ENDC}")
    for n in range(2, N + 1):
        display(f"{bcolors.OKBLUE}{n} {await mpc.output(demos.secretsanta.random_derangement(n, sectype))}{bcolors.ENDC}")


# with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
demos.secretsanta.xprint = xprint
# mpc.run(demos.secretsanta.main())


m = len(mpc.parties)
l = m.bit_length()

mpc.run(mpc.start())
print("m    =", mpc.run(mpc.output(mpc.sum(mpc.input(mpc.SecInt(l + 1)(1))))))
print("m**2 =", mpc.run(mpc.output(mpc.sum(mpc.input(mpc.SecInt(2 * l + 1)(2 * mpc.pid + 1))))))
print("2**m =", mpc.run(mpc.output(mpc.prod(mpc.input(mpc.SecInt(m + 2)(2))))))
print("m!   =", mpc.run(mpc.output(mpc.prod(mpc.input(mpc.SecInt(int(m * (l - 1.4) + 3))(mpc.pid + 1))))))
mpc.run(mpc.shutdown())

import asyncio
from asyncio import futures
import json
import logging
import traceback
import types
from typing import Awaitable

from mpyc.runtime import Party, mpc

# pyright: reportMissingImports=false
from polyscript import xworker

from .debug import *
import ast
from asyncio import AbstractEventLoop

logging = logging.getLogger(__name__)

import inspect


async def run_mpc(options):
    logging.debug("starting mpyc execution...")
    # TODO automatically set the no_async based on the number of parties
    m = len(options.parties)
    mpc.options.threshold = (m - 1) // 2
    mpc.options.no_async = m == 1 and options.no_async

    assert 2 * mpc.options.threshold < m, f"threshold {mpc.options.threshold} too large for {m} parties"

    parties = []
    for pid, peerID in enumerate(options.parties):
        parties.append(Party(pid, peerID))
    mpc.options.parties = parties

    # reinitialize the mpyc runtime with the new parties
    mpc.__init__(options.pid, parties, mpc.options)

    f = await exec_async(options.exec)
    # print("mpc done")


async def exec_async(source: str):
    source = "__name__ = '__main__'\n" + source + "\n"
    code = compile(source, "_mpc_run_compiled.py", "exec", ast.PyCF_ALLOW_TOP_LEVEL_AWAIT)
    func = types.FunctionType(code, globals())
    if asyncio.iscoroutinefunction(func):
        return await func()
    else:
        return func()


xworker.sync.run_mpc = run_mpc

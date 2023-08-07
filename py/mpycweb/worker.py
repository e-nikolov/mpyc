## Receiving stuff from the main JS thread
import asyncio
import json
import logging
from typing import Callable, Any, Coroutine

from mpyc.runtime import Party, mpc
from . import state

# pyright: reportMissingImports=false
from polyscript import xworker

from .debug import *


def run_mpc(data):
    logging.debug("starting mpyc execution...")
    mpc.options.no_async = data.no_async
    parties = []
    for pid, peerID in enumerate(data.parties):
        parties.append(Party(pid, peerID))
    logging.debug(f"setting _____________parties {sdump(parties)}")

    # reinitialize the mpyc runtime with the new parties
    mpc.__init__(data.pid, parties, mpc.options)

    exec(data.exec)

    # for coro in state.mpc_coros:
    #     asyncio.ensure_future(clone_coro(coro))


xworker.sync.run_mpc = run_mpc


def clone_coro(coro: Coroutine):
    function_name = coro.__qualname__
    # function_name = coro.__name__

    func = coro.cr_frame.f_globals[function_name]
    args = coro.cr_frame.f_locals.values()

    return func(*args)

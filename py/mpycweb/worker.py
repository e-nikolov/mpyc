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

logging = logging.getLogger(__name__)


async def run_mpc(data):
    logging.debug("starting mpyc execution...")
    mpc.options.no_async = data.no_async
    m = len(data.parties)

    mpc.options.threshold = (m - 1) // 2

    assert 2 * mpc.options.threshold < m, f"threshold {mpc.options.threshold} too large for {m} parties"

    parties = []
    for pid, peerID in enumerate(data.parties):
        parties.append(Party(pid, peerID))
    logging.debug(f"setting parties {sdump(parties)}")
    mpc.options.parties = parties

    # reinitialize the mpyc runtime with the new parties
    mpc.__init__(data.pid, parties, mpc.options)

    import sys

    __name__ = "__main__"
    code = "".join(f"\n{line}" for line in data.exec.split("\n")) + "\n"

    code = data.exec
    code = "__name__ = '__main__'\n" + code + "\n"

    # sys.path.append(os.path.join(os.path.dirname(__file__), pointdir))
    exec(code, globals())
    # await async_exec(data.exec)
    # xworker.sync.mpcDone()

    # for coro in state.mpc_coros:
    #     asyncio.ensure_future(clone_coro(coro))


# def setup():
#     """Setup a runtime."""
#     if options.threshold is None:
#         options.threshold = (m - 1) // 2
#     assert 2 * options.threshold < m, f"threshold {options.threshold} too large for {m} parties"

#     rt = Runtime(pid, parties, options)
#     sectypes.runtime = rt
#     asyncoro.runtime = rt
#     mpyc.seclists.runtime = rt
#     mpyc.secgroups.runtime = rt
#     mpyc.random.runtime = rt
#     mpyc.statistics.runtime = rt
#     return rt


async def async_exec(code):
    # Make an async function with the code and `exec` it
    exec(f"async def __ex(): " + "".join(f"\n {l}" for l in code.split("\n")))

    # Get `__ex` from local variables, call it and return the result
    return await locals()["__ex"]()


xworker.sync.run_mpc = run_mpc


def clone_coro(coro: Coroutine):
    function_name = coro.__qualname__
    # function_name = coro.__name__

    func = coro.cr_frame.f_globals[function_name]
    args = coro.cr_frame.f_locals.values()

    return func(*args)

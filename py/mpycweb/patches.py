from asyncio import Future, Task
import time
import types
from typing import Coroutine

from .debug import *

from .transport import *
from .worker import *
from . import peerjs
from . import state
from mpyc.runtime import mpc, Runtime

# pyright: reportMissingImports=false
from polyscript import xworker


pjs = peerjs.Client(xworker.sync)


def run(self, f):
    """Run the given coroutine or future until it is done."""
    logging.debug("monkey patched run() %s", f.__class__.__name__)
    """Run the given coroutine or future until it is done."""
    if self._loop.is_running():
        if not asyncio.iscoroutine(f):
            f = asyncoro._wrap_in_coro(f)
            while True:
                try:
                    f.send(None)
                except StopIteration as exc:
                    return exc.value
        else:
            return asyncio.ensure_future(f)
    return self._loop.run_until_complete(f)


mpc.run = types.MethodType(run, mpc)

# def run(self, f: Coroutine | Future) -> None:
#     logging.debug("monkey patched run() %s", f.__class__.__name__)
#     asyncio.ensure_future(f)
#     # if not asyncio.iscoroutine(f):
#     #     print("not a coroutine", f.__class__.__name__)
#     #     f = asyncoro._wrap_in_coro(f)

#     # print("coroutine??", f.__class__.__name__)
#     # state.mpc_coros.append(f)


async def start(runtime: Runtime) -> None:
    """Start the MPyC runtime with a PeerJS transport.

    Open connections with other parties, if any.
    """
    logging.debug("monkey patched start()")
    logging.info(f"Start MPyC runtime v{runtime.version} with a PeerJS transport")
    runtime.start_time = time.time()

    m = len(runtime.parties)
    if m == 1:
        return

    # m > 1
    loop = runtime._loop
    for peer in runtime.parties:
        peer.protocol = asyncio.Future(loop=loop) if peer.pid == runtime.pid else None

    # Listen for all parties < runtime.pid.

    # Connect to all parties > self.pid.
    for peer in runtime.parties:
        if peer.pid == runtime.pid:
            continue

        logging.debug(f"Connecting to {peer}")

        while True:
            try:
                if peer.pid > runtime.pid:
                    factory = lambda: asyncoro.MessageExchanger(runtime, peer.pid)
                else:
                    factory = lambda: asyncoro.MessageExchanger(runtime)

                logging.debug(f"~~~~~~~~~~ creating peerjs connection to {peer.pid}...")

                await pjs.create_connection(runtime._loop, peer.pid, factory)

                logging.debug(f"~~~~~~~~~~ creating peerjs connection to {peer.pid}... done")
                break
            except asyncio.CancelledError:
                raise

            except Exception as exc:
                logging.debug(exc)
            await asyncio.sleep(1)

    logging.info("Waiting for all parties to connect")
    await runtime.parties[runtime.pid].protocol
    logging.info(f"All {m} parties connected.")


mpc.start = types.MethodType(start, mpc)

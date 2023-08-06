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


def run(self, f: Coroutine | Future) -> None:
    logging.debug("monkey patched run() %s", f.__class__.__name__)

    if not asyncio.iscoroutine(f):
        print("not a coroutine", f.__class__.__name__)
        f = asyncoro._wrap_in_coro(f)

    print("coroutine??", f.__class__.__name__)
    state.mpc_coros.append(f)


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

        # while True:
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
            # await asyncio.sleep(1)

    logging.info("Waiting for all parties to connect")
    await runtime.parties[runtime.pid].protocol
    logging.info(f"All parties connected, {'not zero' if runtime.pid else 'zero'}")
    logging.info(f"All {m} parties connected.")


def clone_coro(coro: Coroutine):
    function_name = coro.__qualname__
    # function_name = coro.__name__

    func = coro.cr_frame.f_globals[function_name]
    args = coro.cr_frame.f_locals.values()

    return func(*args)


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

    for coro in state.mpc_coros:
        asyncio.ensure_future(clone_coro(coro))
    # mpc.run(main())


xworker.sync.run_mpc = run_mpc


display("PyScript runtime started.")

# mpc.run = types.MethodType(run, mpc)
# mpc.start = types.MethodType(start, mpc)

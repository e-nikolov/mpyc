import time

from .debug import *

print_tree(Path("../"))

from .transport import *
from .worker import *
import state
from mpyc.runtime import mpc, Runtime

# pyright: reportMissingImports=false
from polyscript import xworker


async def create_connection(runtime, protocol_factory, peerjsID):
    protocol = protocol_factory()
    transport = PeerJSTransport(runtime, protocol, peerjsID)
    return transport, protocol


def run(self, f) -> None:
    state.run_func = f


async def start(runtime: Runtime) -> None:
    """Start the MPyC runtime with a PeerJS transport.

    Open connections with other parties, if any.
    """
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

            transport, _ = await create_connection(runtime, factory, peer.host)
            state.peerTransports[peer.pid] = transport

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


mpc.run = run
mpc.start = start


def init(data):
    logging.debug("starting mpyc execution...")
    if not data.no_async:
        mpc.options.no_async = data.no_async
        parties = []
        for pid, peerID in enumerate(data.parties):
            parties.append(Party(pid, peerID))
            state.peerjsIDToPID[peerID] = pid
        logging.debug(f"setting _____________parties {sdump(state.peerjsIDToPID)} {sdump(parties)}")

        # reinitialize the mpyc runtime with the new parties
        mpc.__init__(data.pid, parties, mpc.options)

    logging.debug(f"$$$$$$$$$$$$$$ Running mpc.run(main())")
    asyncio.ensure_future(state.run_func())
    # mpc.run(main())
    logging.debug(f"$$$$$$$$$$$$$$ Done Running mpc.run(main())")


xworker.onmessage = on_message(init, transport.onReadyMessage, transport.onRuntimeMessage)


def inside_worker():
    logging.debug("inside worker")


xworker.sync.inside_worker = inside_worker

display("PyScript runtime started.")


def onReadyMessage(pid: int, peerjsID: str, ready_message: str):
    logging.debug(f"ready message: {sdump(ready_message)}")  # if we are ready to start, send "ready_ack"
    if ready_message == "ready?":
        logging.debug("we are asked if we are ready!!!!!!!!!!!!!!!")
        logging.debug(f"___________________________________ {sdump(state.peerTransports[pid])}")
        logging.debug(f"___________________________________ {sdump(state.peerTransports[pid].ready_to_start)}")

        if state.peerTransports[pid].ready_to_start:
            peerjs.send_message(peerjsID, new_ready_message("ready_ack"))
            return

    if ready_message == "ready_ack":
        logging.debug("+_+_++_+_+_+_+_+_+_ They are ready to start")
        state.peerTransports[pid].peer_ready_to_start = True


def onRuntimeMessage(pid: int, runtime_message: str):
    state.peerTransports[pid]._protocol.data_received(bytes.fromhex(runtime_message))

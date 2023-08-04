import logging
import sys
import time
from pathlib import Path


logging.basicConfig(
    # force=True, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s", level=logging.DEBUG, stream=sys.stdout
    force=True,
    # format="%(created)f:%(levelname)s:%(pathname)s:%(filename)s:%(funcName)s:%(lineno)s:%(module)s:%(message)s",
    format="[%(asctime)s] {%(name)s:%(lineno)d:%(funcName)s} %(levelname)s %(message)s",
    datefmt="%H:%M:%S",
    level=logging.DEBUG,
    stream=sys.stdout,
)
logging = logging.getLogger("worker.py")


def print_tree(path, prefix="", str=""):
    for item in path.iterdir():
        logging.info(f"{prefix}├── {item.name}")
        if item.is_dir():
            print_tree(item, prefix + "│   ")


# print_tree(Path("."))

import json
import secretsanta as secretsanta
from mpyc import asyncoro
from mpyc.runtime import mpc, Party

from polyscript import xworker
import asyncio
from pprint import pprint, pformat


def sdump(obj):
    s = ""
    try:
        s = pformat(vars(obj), indent=4)
    except TypeError:
        pass

    if s == "":
        try:
            s = pformat(obj, indent=4)
        except TypeError:
            pass

    if s == "":
        try:
            s = pformat(dict(obj), indent=4)
        except TypeError:
            pass

    return f"{type(obj)}: {s}"


def dump(obj):
    logging.debug(sdump(obj))


def display(msg):
    send_message(dict(display=msg))


def new_ready_message(msg):
    return dict(ready_message=msg)


def new_runtime_message(msg):
    return dict(runtime_message=msg.hex())


def send_peerjs_message(peerID, message):
    envelope = dict(peerJS=dict(peerID=peerID, message=message))
    send_message(envelope)


def send_message(msg):
    xworker.postMessage(json.dumps(msg))


# def postPeerJSMessage(peerID, message):
#     logging.debug("(worker.py) ??????????? posting peerJSMessage: ", peerID, message)
#     try:
#         msg = json.dumps({"peerJS": {"peerID": peerID, "message": message.hex()}})
#     except Exception as e:
#         logging.debug("(worker.py) ??????????? ERROR: ", e)

#     logging.debug("(worker.py) ??????????? JSON: ", msg)

#     xworker.postMessage(msg)


def dump(obj):
    try:
        pprint(json.dumps(obj))
    except:
        # for attr in dir(obj):
        #     print("obj.%s = %r" % (attr, getattr(obj, attr)))
        pprint(dir(obj))


class bcolors:
    HEADER = "\033[95m"
    OKBLUE = "\033[94m"
    OKCYAN = "\033[96m"
    OKGREEN = "\033[92m"
    WARNING = "\033[93m"
    FAIL = "\033[91m"
    ENDC = "\033[0m"
    BOLD = "\033[1m"
    UNDERLINE = "\033[4m"


async def xprint(N, text, sectype):
    display(f"{bcolors.UNDERLINE}{bcolors.WARNING}Using secure {text}: {sectype.__name__}{bcolors.ENDC}{bcolors.ENDC}")
    for n in range(2, N + 1):
        display(f"{bcolors.OKBLUE}{n} {await mpc.output(secretsanta.random_derangement(n, sectype))}{bcolors.ENDC}")


async def main():
    logging.debug("&&&&&&&&&&&&&&&&& MAIN() ")
    # print_tree(Path("../"))

    if sys.argv[1:]:
        logging.debug("&&&&&&&&&&&&&&&&&2 MAIN() ")
        N = int(sys.argv[1])
    else:
        logging.debug("&&&&&&&&&&&&&&&&&3 MAIN() ")
        N = 8
        display(f"Setting input to default = {N}")

    logging.debug("&&&&&&&&&&&&&&&&&4 MAIN() ")
    # await mpc.start()
    logging.debug(".................. awaiting start runtime .......................")
    await start_runtime(mpc)
    logging.debug(".................. done awaiting start runtime .......................")

    await xprint(N, "integers", mpc.SecInt())
    await xprint(N, "fixed-point numbers", mpc.SecFxp())
    bound = max(len(mpc.parties) + 1, N)
    await xprint(N, "prime fields", mpc.SecFld(min_order=bound))
    await xprint(N, "binary fields", mpc.SecFld(char=2, min_order=bound))
    await xprint(N, "quinary fields", mpc.SecFld(char=5, min_order=bound))
    await xprint(N, "extension fields (medium prime)", mpc.SecFld(order=11**7))
    await xprint(N, "extension fields (larger prime)", mpc.SecFld(order=1031**3))

    await mpc.shutdown()


class PeerJSTransport(asyncio.Transport):
    ready_to_start = False

    def __init__(self, runtime, protocol, peerjs_id):
        super().__init__()
        self.runtime = runtime
        self._loop = runtime._loop
        self.set_protocol(protocol)
        self._closing = False
        self.peerjs_id = peerjs_id

        self.ready_to_start = True
        self.peer_ready_to_start = False

        # need to coordinate the start of running the demo with all peers
        # send "are you ready?" messages every second and call connection_made when all peers are ready
        self._loop.create_task(self._ready_for_connections())

    def is_closing(self):
        return self._closing

    def close(self):
        self._closing = True

    def set_protocol(self, protocol):
        self._protocol = protocol

    def get_protocol(self):
        return self._protocol

    def write(self, data):
        """Write some data bytes to the transport.

        This does not block; it buffers the data and arranges for it
        to be sent out asynchronously.
        """
        logging.debug("<<<<<<<<<<<<<<<<<< writing data...")
        # postPeerJSMessage(self.peerjs_id, new_runtime_message(data))
        send_peerjs_message(self.peerjs_id, new_runtime_message(data))
        logging.debug("<<<<<<<<<<<<<<<<<< writing data... done")

    async def _ready_for_connections(self):
        while not self.peer_ready_to_start:
            ## send ready messages to this connection's peer to check if the user has clicked "run mpyc demo"
            send_peerjs_message(self.peerjs_id, new_ready_message("ready?"))
            await asyncio.sleep(3)

        try:
            self._loop.call_soon(self._protocol.connection_made, self)
        except Exception as exc:
            logging.debug(exc)


async def create_peerjs_connection(runtime, protocol_factory, peerjsID):
    protocol = protocol_factory()
    transport = PeerJSTransport(runtime, protocol, peerjsID)
    return transport, protocol


async def start_runtime(runtime):
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

            transport, _ = await create_peerjs_connection(runtime, factory, peer.host)
            peerTransports[peer.pid] = transport

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


peerjsIDToPID = {}
peerTransports = {}

display("PyScript runtime started.")


## Receiving stuff from the main JS thread
def on_message(event):
    logging.debug("!!!!!!!!!!!!!!!! ON MESSAGE !!!!!!!!!!!!!!!!!!!!!")

    if event.data.init:
        logging.debug("_______________________INIT")
        if not event.data.init.no_async:
            mpc.options.no_async = event.data.init.no_async
            # dump(event.data.init)
            parties = []
            pid = 0
            for peerID in event.data.init.parties:
                parties.append(Party(pid, peerID))
                peerjsIDToPID[peerID] = pid
                pid += 1
            logging.debug(f"setting _____________parties {sdump(peerjsIDToPID)} {sdump(parties)}")

            # reinitialize the mpyc runtime with the new parties
            mpc.__init__(event.data.init.pid, parties, mpc.options)
            # mpc.pid = event.data.init.pid
            # mpc.parties = parties

        logging.debug(f"$$$$$$$$$$$$$$ Running mpc.run(main())")
        asyncio.ensure_future(main())
        # mpc.run(main())
        logging.debug(f"$$$$$$$$$$$$$$ Done Running mpc.run(main())")

    if event.data.peerJS:
        logging.debug(f"peerJS: {event.data.peerJS.peerID}")

        if event.data.peerJS.peerID not in peerjsIDToPID:
            logging.debug(f"___________________ unknown peer id: {event.data.peerJS.peerID}")
            logging.debug(f"___________________ peers: {sdump(peerjsIDToPID)}")
            return

        pid = peerjsIDToPID.get(event.data.peerJS.peerID)

        # logging.debug("peerJS: ", event.data.peerJS.message.ready_message)
        if event.data.peerJS.message.ready_message:
            logging.debug(f"ready message: {sdump(event.data.peerJS.message.ready_message)}")
            # if we are ready to start, send "ready_ack"
            if event.data.peerJS.message.ready_message == "ready?":
                logging.debug("we are asked if we are ready!!!!!!!!!!!!!!!")
                logging.debug(f"___________________________________ {sdump(peerTransports[pid])}")
                logging.debug(f"___________________________________ {sdump(peerTransports[pid].ready_to_start)}")

                if peerTransports[pid].ready_to_start:
                    send_peerjs_message(event.data.peerJS.peerID, new_ready_message("ready_ack"))
                    return

            if event.data.peerJS.message.ready_message == "ready_ack":
                logging.debug("+_+_++_+_+_+_+_+_+_ They are ready to start")
                peerTransports[pid].peer_ready_to_start = True

        if event.data.peerJS.message.runtime_message:
            mpc.parties[pid].protocol.data_received(bytes.fromhex(event.data.peerJS.message.runtime_message))


xworker.onmessage = on_message

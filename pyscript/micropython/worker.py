import json
import time
import base64
from mpyc import asyncoro
import secretsanta
from mpyc.runtime import mpc, Party

from xworker import xworker
import asyncio
from pathlib import Path
import sys
import logging
from pprint import pprint


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
#     print("(worker.py) ??????????? posting peerJSMessage: ", peerID, message)
#     try:
#         msg = json.dumps({"peerJS": {"peerID": peerID, "message": message.hex()}})
#     except Exception as e:
#         print("(worker.py) ??????????? ERROR: ", e)

#     print("(worker.py) ??????????? JSON: ", msg)

#     xworker.postMessage(msg)


def dump(obj):
    try:
        print(json.dumps(obj))
    except:
        for attr in dir(obj):
            print("obj.%s = %r" % (attr, getattr(obj, attr)))


def print_tree(path, prefix="", str=""):
    for item in path.iterdir():
        print(f"{prefix}├── {item.name}")
        if item.is_dir():
            print_tree(item, prefix + "│   ")


async def xprint(N, text, sectype):
    display(f"Using secure {text}: {sectype.__name__}")
    for n in range(2, N + 1):
        display(f"{n} {await mpc.output(secretsanta.random_derangement(n, sectype))}")


async def main():
    print("&&&&&&&&&&&&&&&&& MAIN() ")
    # print_tree(Path("../"))

    if sys.argv[1:]:
        print("&&&&&&&&&&&&&&&&&2 MAIN() ")
        N = int(sys.argv[1])
    else:
        print("&&&&&&&&&&&&&&&&&3 MAIN() ")
        N = 8
        display(f"Setting input to default = {N}")

    print("&&&&&&&&&&&&&&&&&4 MAIN() ")
    # await mpc.start()
    print(".................. awaiting start runtime .......................")
    await start_runtime(mpc)
    print(".................. done awaiting start runtime .......................")

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
        print("(worker.py:PeerJSTransport): <<<<<<<<<<<<<<<<<< writing data")
        # postPeerJSMessage(self.peerjs_id, new_runtime_message(data))
        send_peerjs_message(self.peerjs_id, new_runtime_message(data))
        print("(worker.py:PeerJSTransport): <<<<<<<<<<<<<<<<<< done writing data")

    async def _ready_for_connections(self):
        while not self.peer_ready_to_start:
            ## send ready messages to this connection's peer to check if the user has clicked "run mpyc demo"
            send_peerjs_message(self.peerjs_id, new_ready_message("ready?"))
            await asyncio.sleep(1)

        try:
            self._loop.call_soon(self._protocol.connection_made, self)
        except Exception as exc:
            print(exc)


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

        while True:
            try:
                if peer.pid > runtime.pid:
                    factory = lambda: asyncoro.MessageExchanger(runtime, peer.pid)
                else:
                    factory = lambda: asyncoro.MessageExchanger(runtime)

                await create_peerjs_connection(runtime, factory, peer.host)
                break
            except asyncio.CancelledError:
                raise

            except Exception as exc:
                logging.debug(exc)
            asyncio.sleep(1)

    logging.info("Waiting for all parties to connect")
    await runtime.parties[runtime.pid].protocol
    logging.info(f"All parties connected, {'not zero' if runtime.pid else 'zero'}")
    logging.info(f"All {m} parties connected.")


peerjsIDToPID = {}


def on_message(event):
    print("(worker.py:on_message): !!!!!!!!!!!!!!!! ON MESSAGE !!!!!!!!!!!!!!!!!!!!!")
    if getattr(event.data, "init", None):
        if not event.data.init.no_async:
            mpc.options.no_async = event.data.init.no_async
            # dump(event.data.init)
            parties = []
            pid = 0
            for peerID in event.data.init.parties:
                parties.append(Party(pid, peerID))
                peerjsIDToPID[peerID] = pid
                pid += 1
            print("parties")
            print(parties)

            # reinitialize the mpyc runtime with the new parties
            mpc.__init__(event.data.init.pid, parties, mpc.options)
            # mpc.pid = event.data.init.pid
            # mpc.parties = parties

        print("$$$$$$$$$$$$$$ Running mpc.run(main())")
        asyncio.ensure_future(main())
        # mpc.run(main())
        print("$$$$$$$$$$$$$$ Done Running mpc.run(main())")

    if getattr(event.data, "peerJS", None):
        print("peerJS: ", event.data.peerJS)
        pid = peerjsIDToPID[event.data.peerJS.peerID]

        if getattr(event.data.peerJS.message, "ready_message", None):
            print("ready message: ", event.data.peerJS.message.ready_message)
            # if we are ready to start, send "ready_ack"
            if event.data.peerJS.message.ready_message == "ready?":
                if (
                    mpc.parties[pid].protocol
                    and mpc.parties[pid].protocol.transport
                    and mpc.parties[pid].protocol.transport.ready_to_start
                ):
                    send_peerjs_message(
                        event.data.peerJS.peerID, new_ready_message("ready_ack")
                    )
            if event.data.peerJS.message.ready_message == "ready_ack":
                mpc.parties[pid].protocol.transport.peer_ready_to_start = True

        if getattr(event.data.peerJS.message, "runtime_message", None):
            mpc.parties[pid].protocol.data_received(
                bytes.fromhex(event.data.peerJS.message.runtime_message)
            )


xworker.onmessage = on_message

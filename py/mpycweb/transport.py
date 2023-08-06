import json
import asyncio
import logging
from typing import Any

# pyright: reportMissingImports=false
from . import peerjs

logging = logging.getLogger("transport.py")

import secretsanta as secretsanta
from mpyc import asyncoro
from mpyc.runtime import mpc, Party
from debug import sdump, dump, print_tree


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

    def set_protocol(self, protocol: asyncoro.MessageExchanger):
        self._protocol = protocol

    def get_protocol(self):
        return self._protocol

    def data_received(self, data):
        pass

    def write(self, data):
        """Write some data bytes to the transport.

        This does not block; it buffers the data and arranges for it
        to be sent out asynchronously.
        """
        logging.debug("<<<<<<<<<<<<<<<<<< writing data...")
        # postPeerJSMessage(self.peerjs_id, new_runtime_message(data))
        peerjs.send_message(self.peerjs_id, new_runtime_message(data))
        logging.debug("<<<<<<<<<<<<<<<<<< writing data... done")

    async def _ready_for_connections(self):
        while not self.peer_ready_to_start:
            ## send ready messages to this connection's peer to check if the user has clicked "run mpyc demo"
            peerjs.send_message(self.peerjs_id, new_ready_message("ready?"))
            await asyncio.sleep(3)

        try:
            self._loop.call_soon(self._protocol.connection_made, self)
        except Exception as exc:
            logging.debug(exc)


def new_ready_message(msg):
    return dict(ready_message=msg)


def new_runtime_message(msg):
    return dict(runtime_message=msg.hex())

import json
import asyncio
import logging
from typing import Any

# pyright: reportMissingImports=false
logging = logging.getLogger("transport.py")

from mpyc import asyncoro
from mpyc.runtime import mpc, Party, Runtime
from .debug import *


class AbstractClient:
    def send_runtime_message(self, pid: int, message: bytes):
        raise NotImplementedError

    def send_ready_message(self, pid: int, message: str):
        raise NotImplementedError


class PeerJSTransport(asyncio.Transport):
    def __init__(
        self,
        _loop: asyncio.AbstractEventLoop,
        pid: int,
        client: AbstractClient,
        protocol: asyncoro.MessageExchanger,
        listener: bool,
    ):
        super().__init__()
        self._loop = _loop
        self._protocol = protocol
        self._listener = listener
        self._closing = False
        self.pid = pid
        self.client = client

        self.ready_to_start = True
        self.peer_ready_to_start = False

        # need to coordinate the start of running the demo with all peers
        # send "are you ready?" messages every second and call connection_made when all peers are ready
        if not self._listener:
            self._loop.create_task(self._connect_to_peer())

    async def _connect_to_peer(self):
        while not self.peer_ready_to_start:
            ## send ready messages to this connection's peer to check if the user has clicked "run mpyc demo"
            self.client.send_ready_message(self.pid, "ready?")
            await asyncio.sleep(1)

    def write(self, data: bytes):
        """Write some data bytes to the transport.

        This does not block; it buffers the data and arranges for it
        to be sent out asynchronously.
        """
        self.client.send_runtime_message(self.pid, data)

    def on_runtime_message(self, message: bytes):
        # logging.debug(f"received {message} from {self.pid}")
        self._protocol.data_received(message)

    def on_ready_message(self, message: str):
        match message:
            case "ready?":
                logging.debug(f"party {self.pid} asks if we are ready to start")
                if self.ready_to_start:
                    self._protocol.connection_made(self)
                    self.client.send_ready_message(self.pid, "ready_ack")

            case "ready_ack":
                logging.debug(f"party {self.pid} confirmed ready to start")
                # self._loop.call_soon(self._protocol.connection_made, self)
                self.peer_ready_to_start = True
                self._protocol.connection_made(self)

    def is_closing(self):
        return self._closing

    def close(self):
        self._closing = True
        self._protocol.connection_lost(None)

    def set_protocol(self, protocol: asyncoro.MessageExchanger):
        self._protocol = protocol

    def get_protocol(self):
        return self._protocol

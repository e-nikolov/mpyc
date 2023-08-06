import json
import asyncio
import logging
from typing import Any

# pyright: reportMissingImports=false
from polyscript import xworker

logging = logging.getLogger("peerjs.py")

from mpyc import asyncoro
from mpyc.runtime import mpc, Party, Runtime
from .debug import *
from . import worker
from . import transport


class Client(transport.AbstractClient):
    def __init__(self, worker: Any):
        self.worker = worker

        self.worker.on_ready_message = self.on_ready_message
        self.worker.on_runtime_message = self.on_runtime_message

        self.transports = {}

    async def create_connection(self, loop: asyncio.AbstractEventLoop, pid: int, protocol_factory):
        p = protocol_factory()
        t = transport.PeerJSTransport(loop, pid, self, p)
        self.transports[pid] = t

        return t, p

    def send_runtime_message(self, pid: int, message: bytes):
        self.worker.sendRuntimeMessage(pid, message.hex())

    def on_runtime_message(self, pid: int, runtime_message: str):
        self.transports[pid].on_runtime_message(bytes.fromhex(runtime_message))

    def send_ready_message(self, pid: int, message: str):
        xworker.sendReadyMessage(pid, message)

    def on_ready_message(self, pid: int, ready_message: str):
        logging.debug(f"ready message: {sdump(ready_message)}")  # if we are ready to start, send "ready_ack"
        self.transports[pid].on_ready_message(ready_message)

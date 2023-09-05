import json
from asyncio import AbstractEventLoop, Future, Protocol, Transport
import logging
from typing import Any, Callable

logging = logging.getLogger("peerjs.py")

from mpyc import asyncoro
from mpyc.runtime import mpc, Party, Runtime
from .debug import *
from . import worker
from .transport import PeerJSTransport, AbstractClient
from pyodide.ffi import JsProxy


class Client(AbstractClient):
    def __init__(self, worker: Any):
        self.worker = worker

        self.worker.on_ready_message = self.on_ready_message
        self.worker.on_runtime_message = self.on_runtime_message

        self.transports = {}

    async def create_connection(
        self, protocol_factory: Callable[[], asyncoro.MessageExchanger], loop: AbstractEventLoop, pid: int, listener: bool
    ) -> tuple[Transport, Protocol]:
        p = protocol_factory()
        t = PeerJSTransport(loop, pid, self, p, listener)
        self.transports[pid] = t
        return t, p

    def send_ready_message(self, pid: int, message: str):
        self.worker.sendReadyMessage(pid, message)

    def on_ready_message(self, pid: int, ready_message: str):
        self.transports[pid].on_ready_message(ready_message)

    def send_runtime_message(self, pid: int, message: bytes):
        # logging.debug(f"sending {message} to {pid}")
        self.worker.sendRuntimeMessage(pid, message)

    def on_runtime_message(self, pid: int, runtime_message: JsProxy):
        # logging.debug(f"received {runtime_message} from {pid}")
        self.transports[pid].on_runtime_message(runtime_message.to_py())

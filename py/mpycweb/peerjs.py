import json
from asyncio import AbstractEventLoop, Future, Protocol, Transport
import logging
from typing import Any, Callable

# pyright: reportMissingImports=false
logging = logging.getLogger("peerjs.py")

from mpyc import asyncoro
from mpyc.runtime import mpc, Party, Runtime
from .debug import *
from . import worker
from .transport import PeerJSTransport, AbstractClient


class Client(AbstractClient):
    def __init__(self, worker: Any):
        self.worker = worker

        self.worker.on_ready_message = self.on_ready_message
        self.worker.on_runtime_message = self.on_runtime_message

        self.transports = {}

    async def create_connection(
        self, protocol_factory: Callable[[], asyncoro.MessageExchanger], loop: AbstractEventLoop, pid: int, listener: bool
    ) -> tuple[Future[Transport], Future[Protocol]]:
        p = protocol_factory()
        t = PeerJSTransport(loop, pid, self, p, listener)
        self.transports[pid] = t

        ft: Future[Transport] = loop.create_future()
        ft.set_result(t)

        fp: Future[Protocol] = loop.create_future()
        fp.set_result(p)

        return ft, fp

    def send_ready_message(self, pid: int, message: str):
        self.worker.sendReadyMessage(pid, message)

    def on_ready_message(self, pid: int, ready_message: str):
        self.transports[pid].on_ready_message(ready_message)

    def send_runtime_message(self, pid: int, message: str):
        logging.debug(f"sending {message} to {pid}")
        self.worker.sendRuntimeMessage(pid, message)

    def on_runtime_message(self, pid: int, runtime_message: str):
        # logging.debug(f"received {runtime_message} from {pid}")
        self.transports[pid].on_runtime_message(runtime_message)

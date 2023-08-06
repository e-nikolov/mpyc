## Receiving stuff from the main JS thread
import asyncio
import json
import logging
from typing import Callable, Any

from mpyc.runtime import mpc

# pyright: reportMissingImports=false
from polyscript import xworker

from .debug import *

from . import state


def send_message(msg):
    xworker.postMessage(json.dumps(msg))


def on_message(
    onInit: Callable[[Any], None], onReadyMessage: Callable[[int, str, str], None], onRuntimeMessage: Callable[[int, str], None]
) -> Callable[[Any], None]:
    def _on_message(event) -> None:
        logging.debug("message received from main JS thread")

        if event.data.init:
            onInit(event.data.init)
        if event.data.peerJS:
            logging.debug(f"peerJS: {event.data.peerJS.peerID}")

            if event.data.peerJS.peerID not in state.peerjsIDToPID:
                logging.debug(f"___________________ unknown peer id: {event.data.peerJS.peerID}")
                logging.debug(f"___________________ peers: {sdump(state.peerjsIDToPID)}")
                return

            pid = state.peerjsIDToPID[event.data.peerJS.peerID]

            # logging.debug("peerJS: ", event.data.peerJS.message.ready_message)
            if event.data.peerJS.message.ready_message:
                onReadyMessage(pid, event.data.peerJS.peerID, event.data.peerJS.message.ready_message)

            if event.data.peerJS.message.runtime_message:
                onRuntimeMessage(pid, event.data.peerJS.message.runtime_message)

    return _on_message

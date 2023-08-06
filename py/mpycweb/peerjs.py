import json
import asyncio
import logging

# pyright: reportMissingImports=false
from polyscript import xworker

logging = logging.getLogger("peerjs.py")

import secretsanta as secretsanta
from mpyc import asyncoro
from mpyc.runtime import mpc, Party
from .debug import *
from . import worker


def send_message(peerID, message):
    envelope = dict(peerJS=dict(peerID=peerID, message=message))
    worker.send_message(envelope)

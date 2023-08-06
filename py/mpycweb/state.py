from typing import Dict
from . import transport


peerjsIDToPID: dict[str, int] = {}
peerTransports: dict[int, transport.PeerJSTransport] = {}


async def run_func() -> None:
    pass

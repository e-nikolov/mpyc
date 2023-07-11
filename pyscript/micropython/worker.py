import secretsanta
from mpyc.runtime import mpc

from xworker import xworker
import asyncio
from pathlib import Path
import sys

display = xworker.postMessage


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
    print_tree(Path("../"))

    if sys.argv[1:]:
        N = int(sys.argv[1])
    else:
        N = 8
        display(f"Setting input to default = {N}")
        display("test----------------------------")

    await mpc.start()

    await xprint(N, "integers", mpc.SecInt())
    await xprint(N, "fixed-point numbers", mpc.SecFxp())
    bound = max(len(mpc.parties) + 1, N)
    await xprint(N, "prime fields", mpc.SecFld(min_order=bound))
    await xprint(N, "binary fields", mpc.SecFld(char=2, min_order=bound))
    await xprint(N, "quinary fields", mpc.SecFld(char=5, min_order=bound))
    await xprint(N, "extension fields (medium prime)", mpc.SecFld(order=11**7))
    await xprint(N, "extension fields (larger prime)", mpc.SecFld(order=1031**3))

    await mpc.shutdown()


def on_message(event):
    # display(event)
    print(event.data)
    mpc.run(main())
    # asyncio.ensure_future(main())

    # xworker.postMessage("Python: Hello " + event.data + " 👋")

    # xworker.window.document.body.append("????????????????????")


def run():
    print("loop: ", asyncio.get_event_loop().is_running())

    # mpc.run(main())
    # asyncio.ensure_future(main())


xworker.onmessage = on_message

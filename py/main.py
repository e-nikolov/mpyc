# pyright: reportMissingImports=false

from mpycweb.debug import *

# print_tree(Path("./"))
import asyncio
from polyscript import xworker
import mpycweb.redirect_stdout
import logging_setup
from pathlib import Path
from mpyc.runtime import mpc
import mpycweb
from mpycweb import bcolors, display, print_tree
import demos.secretsanta
from demos.secretsanta import *

# import demos.oneliners


async def xprint(N, text, sectype) -> None:
    display(f"{bcolors.UNDERLINE}{bcolors.WARNING}Using secure {text}: {sectype.__name__}{bcolors.ENDC}{bcolors.ENDC}")
    for n in range(2, N + 1):
        display(f"{bcolors.OKBLUE}{n} {await mpc.output(random_derangement(n, sectype))}{bcolors.ENDC}")


print("mpc.options.no_async")
print(mpc.options.no_async)
# demos.secretsanta.xprint = xprint
asyncio.ensure_future(demos.secretsanta.main())
# mpc.run(demos.secretsanta.main())


# m = len(mpc.parties)
# l = m.bit_length()

# mpc.run(mpc.start())
# print("m    =", mpc.run(mpc.output(mpc.sum(mpc.input(mpc.SecInt(l + 1)(1))))))
# print("m**2 =", mpc.run(mpc.output(mpc.sum(mpc.input(mpc.SecInt(2 * l + 1)(2 * mpc.pid + 1))))))
# print("2**m =", mpc.run(mpc.output(mpc.prod(mpc.input(mpc.SecInt(m + 2)(2))))))
# print("m!   =", mpc.run(mpc.output(mpc.prod(mpc.input(mpc.SecInt(int(m * (l - 1.4) + 3))(mpc.pid + 1))))))
# mpc.run(mpc.shutdown())

from mpycweb.debug import *
from mpyc.runtime import mpc
import demos.secretsanta


async def main():
    await demos.secretsanta.main()


mpc.run(main())

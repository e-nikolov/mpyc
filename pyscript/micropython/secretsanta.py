"""Demo solution to the Secret Santa problem.

The Secret Santa problem is about generating secret random permutations
without fixed points. A fixed point of a permutation p is a point i for
which p(i)=i, hence the point is mapped to itself. Permutations without
fixed points are also called 'derangements'.
"""

import sys
from mpyc.runtime import mpc
import asyncio

from pathlib import Path
import io


from js import document

# js.document.querySelector("py-terminal").xtermReady


# def sprint(*args, **kwargs):
#     output = io.StringIO()
#     print(*args, file=output, **kwargs)
#     contents = output.getvalue()
#     output.close()
#     return contents


# def display(s):
#     # document.currentScript.target.textContent += sprint(args, kwargs)
#     document.term.writeln(s)
#     print(s)


def display(*values):
    document.term.write(values[0])
    if len(values) > 1:
        document.term.write(values[1])
    document.term.writeln("")


def print_tree(path, prefix="", str=""):
    for item in path.iterdir():
        display(f"{prefix}├── {item.name}")
        if item.is_dir():
            print_tree(item, prefix + "│   ")


# import uvloop


@mpc.coroutine
async def random_unit_vector(n, sectype):
    """Random permutation of [sectype(1)] + [sectype(0) for i in range(n-1)]."""
    await mpc.returnType((sectype, True), n)
    if n == 1:
        return [sectype(1)]

    b = mpc.random_bit(sectype)
    x = random_unit_vector((n + 1) // 2, sectype)
    if n % 2 == 0:
        y = mpc.scalar_mul(b, x)
        return y + mpc.vector_sub(x, y)

    if not await mpc.output(b * x[0]):
        y = mpc.scalar_mul(b, x[1:])
        return x[:1] + y + mpc.vector_sub(x[1:], y)

    return random_unit_vector(n, sectype)


def random_permutation(n, sectype):
    """Random permutation of [sectype(i) for i in range(n)]."""
    p = [sectype(i) for i in range(n)]
    for i in range(n - 1):
        x_r = random_unit_vector(n - i, sectype)
        p_r = mpc.in_prod(p[i:], x_r)
        d_r = mpc.scalar_mul(p[i] - p_r, x_r)
        p[i] = p_r
        for j in range(n - i):
            p[i + j] += d_r[j]
    return p


@mpc.coroutine
async def random_derangement(n, sectype):
    """Random permutation of [sectype(i) for i in range(n)] without fixed point."""
    await mpc.returnType((sectype, True), n)
    p = random_permutation(n, sectype)
    t = mpc.prod([p[i] - i for i in range(n)])
    if await mpc.is_zero_public(t):
        p = random_derangement(n, sectype)
    return p


async def xprint(N, text, sectype):
    display(f"Using secure {text}: {sectype.__name__}")
    for n in range(2, N + 1):
        display(f"{n} {await mpc.output(random_derangement(n, sectype))}")


async def main():
    print_tree(Path("../"))

    if sys.argv[1:]:
        N = int(sys.argv[1])
    else:
        N = 8
        display("Setting input to default =", N)
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


async def tt():
    display("asyncio.get_event_loop().is_running()")
    display(asyncio.get_event_loop().is_running())
    display(asyncio.get_event_loop().is_running())


mpc.options.no_async = False
print("asyncio.get_event_loop().is_running()", asyncio.get_event_loop().is_running())

# mpc.run(main())
asyncio.ensure_future(main())


# if __name__ == "__main__":
# mpc.run(main())
# print(asyncio.get_event_loop().stop())
# print(loop := asyncio.new_event_loop())
# print(loop2 := asyncio.new_event_loop())
# print(loop.is_running())
# print("-------------------1")
# print(loop.run_until_complete(tt()))
# print("-------------------2")
# print(loop.is_running())
# print("-------------------3")
# print(loop2.is_running())
# print("-------------------4")
# print(loop2.run_until_complete(asyncio.sleep(1)))
# print(loop2.is_running())
# print("-------------------")
# print(loop.is_running())
# print(loop.is_running())
# print(loop.is_running())
# print(loop.is_running())
# print(loop.is_running())
# asyncio.sleep(2)
# print(loop.is_running())
# mpc.run(main())

# mpc.run(main())
# with asyncio.Runner(loop_factory=uvloop.new_event_loop) as runner:
# runner.run(main())
# asyncio.run_until_complete(main())

"""Demo solution to the Secret Santa problem.

The Secret Santa problem is about generating secret random permutations
without fixed points. A fixed point of a permutation p is a point i for
which p(i)=i, hence the point is mapped to itself. Permutations without
fixed points are also called 'derangements'.
"""

import sys
from mpyc.runtime import mpc


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
    print(f"Using secure {text}: {sectype.__name__}")
    for n in range(2, N + 1):
        print("===========")
        print(await mpc.output(11))
        print("===========")
        print("===========")
        print(await mpc.output(22))
        print("===========")
        print("===========")
        print(await mpc.output(33))
        print("===========")
        print("===========")
        print(await mpc.output(44))
        print("===========")
        a = random_derangement(n, sectype)
        print("===========")
        b = mpc.output(a)

        print("-----------")
        print(b)
        print("-----------")
        print(b.__class__)
        print("-----------")
        print(b.__str__)
        print("-----------")

        c = await b

        print(n, c)


async def main():
    if sys.argv[1:]:
        N = int(sys.argv[1])
    else:
        N = 8
        print("Setting input to default =", N)
    print("1")
    x = await mpc.start()
    print("2")
    print(x)

    z = await xprint(N, "integers", mpc.SecInt())
    print("3")
    print(z)

    await xprint(N, "fixed-point numbers", mpc.SecFxp())
    bound = max(len(mpc.parties) + 1, N)
    await xprint(N, "prime fields", mpc.SecFld(min_order=bound))
    await xprint(N, "binary fields", mpc.SecFld(char=2, min_order=bound))
    await xprint(N, "quinary fields", mpc.SecFld(char=5, min_order=bound))
    await xprint(N, "extension fields (medium prime)", mpc.SecFld(order=11**7))
    await xprint(N, "extension fields (larger prime)", mpc.SecFld(order=1031**3))

    await mpc.shutdown()


async def zz():
    return 3


async def foo():
    z = await zz()
    print(z)
    z = await zz()
    print(z)
    z = await zz()
    print(z)


if __name__ == "__main__":
    # mpc.run(foo())

    mpc.run(main())

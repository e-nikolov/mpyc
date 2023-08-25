## Receiving stuff from the main JS thread
import asyncio
from asyncio import futures
import json
import logging
import traceback
import types
from typing import Awaitable

from mpyc.runtime import Party, mpc

# pyright: reportMissingImports=false
from polyscript import xworker

from .debug import *
import ast
from asyncio import AbstractEventLoop

logging = logging.getLogger(__name__)

import inspect


async def run_mpc(data):
    logging.debug("starting mpyc execution...")
    mpc.options.no_async = data.no_async
    m = len(data.parties)

    mpc.options.threshold = (m - 1) // 2

    assert 2 * mpc.options.threshold < m, f"threshold {mpc.options.threshold} too large for {m} parties"

    parties = []
    for pid, peerID in enumerate(data.parties):
        parties.append(Party(pid, peerID))
    logging.debug(f"setting parties {sdump(parties)}")
    mpc.options.parties = parties

    # reinitialize the mpyc runtime with the new parties
    mpc.__init__(data.pid, parties, mpc.options)

    f = await exec_async(data.exec)
    # print("mpc done")


async def exec_async(source: str):
    source = "__name__ = '__main__'\n" + source + "\n"
    code = compile(source, "_mpc_run_compiled.py", "exec", ast.PyCF_ALLOW_TOP_LEVEL_AWAIT)
    func = types.FunctionType(code, globals())
    if asyncio.iscoroutinefunction(func):
        return await func()
    else:
        return func()


def runcode(loop: AbstractEventLoop, coro: types.FunctionType):
    future = asyncio.Future()

    def callback():
        print("callback? 1")
        global inner_future
        inner_future = None

        print("callback? 2")
        if not asyncio.iscoroutine(coro):
            future.set_result(coro)
            return

        print("callback? 3")
        try:
            inner_future = loop.create_task(coro)
            futures._chain_future(inner_future, future)
        except BaseException as exc:
            future.set_exception(exc)
        print("callback? 4")

    print(loop.call_soon_threadsafe)
    print(loop.call_soon)
    loop.call_soon(callback)
    print("called soon?")
    return future.result()
    # try:

    # except:
    #     traceback.print_stack()


def runcode2(loop: AbstractEventLoop, code: types.CodeType):
    future = asyncio.Future()

    def callback():
        global inner_future
        inner_future = None

        func = types.FunctionType(code, globals())
        # func = types.FunctionType(code, locals())
        try:
            coro = func()
        except SystemExit:
            raise

        except BaseException as ex:
            future.set_exception(ex)
            return

        print("callback? 2")
        if not inspect.iscoroutine(coro):
            future.set_result(coro)
            return

        print("callback? 3")
        try:
            inner_future = loop.create_task(coro)
            futures._chain_future(inner_future, future)
        except BaseException as exc:
            future.set_exception(exc)
        print("callback? 4")

    print(loop.call_soon_threadsafe)
    print(loop.call_soon)
    loop.call_soon(callback)
    print("called soon?")

    return future.result()
    # try:
    # except BaseException:
    #     traceback.print_stack()


xworker.sync.run_mpc = run_mpc

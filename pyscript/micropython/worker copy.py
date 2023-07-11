import secretsanta
from mpyc.runtime import mpc

from xworker import xworker
import asyncio

from contextlib import redirect_stdout
import io


# this code is just for demo purpose but the basics work
def _display(what, target="${id}", append=True):
    document = xworker.window.document

    element = document.getElementById(target)
    element.textContent = what


display = _display
import io
import sys
import contextlib


@contextlib.contextmanager
def capture_output():
    output = {}
    try:
        # Redirect
        sys.stdout = io.TextIOWrapper(io.BytesIO(), sys.stdout.encoding)
        sys.stderr = io.TextIOWrapper(io.BytesIO(), sys.stderr.encoding)
        yield output
    finally:
        # Read
        sys.stdout.seek(0)
        sys.stderr.seek(0)
        output["stdout"] = sys.stdout.read()
        output["stderr"] = sys.stderr.read()
        sys.stdout.close()
        sys.stderr.close()

        # Restore
        sys.stdout = sys.__stdout__
        sys.stderr = sys.__stderr__


with capture_output() as output:
    print("foo")
    await asyncio.sleep(2)
    print("foo2")
    await asyncio.sleep(2)
    print("foo3")
    await asyncio.sleep(2)
    print("foo4")
    sys.stderr.buffer.write(b"bar")

print("stdout: {stdout}".format(stdout=output["stdout"]))
print("stderr: {stderr}".format(stderr=output["stderr"]))

print("stdout: {stdout}".format(stdout=output["stdout"]))
print("stderr: {stderr}".format(stderr=output["stderr"]))


def on_message(event):
    # display(event)
    print(event.data)

    # xworker.postMessage("Python: Hello " + event.data + " 👋")

    # xworker.window.document.body.append("????????????????????")


def run():
    print("loop: ", asyncio.get_event_loop().is_running())

    # mpc.run(main())
    # asyncio.ensure_future(main())


xworker.onmessage = on_message

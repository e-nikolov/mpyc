import asyncio
from collections.abc import Iterable
from contextlib import redirect_stdout
import io
import sys

from .debug import *


class MyWriter(io.StringIO):
    def write(self, text):
        displayRaw(text)


out = MyWriter()
err = MyWriter()

sys.stdout = out
sys.stderr = err

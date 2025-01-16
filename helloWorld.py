#!/usr/bin/python
import signal
import time


def handler(signum, frame):
    print(f'Caught exception: {signum}', flush=True)
    print("Exiting...", flush=True)


if __name__ == "__main__":
    print("Hello World!", flush=True)
    print("Waiting for signal.USR1...", flush=True)
    signal.signal(signal.SIGUSR1, handler)
    while True:
        pass
    # time.sleep(200)
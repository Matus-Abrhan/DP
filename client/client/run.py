import sys

from client.app import Capture


def run():
    if len(sys.argv) < 3:
        print('Too few arguments')
        exit()
    ip_addr = sys.argv[1]
    port = int(sys.argv[2])
    capture = Capture(ip_addr, port)
    with capture.cm() as capture:
        capture.send()


if __name__ == '__main__':
    run()

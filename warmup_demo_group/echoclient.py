""" Simple Client Example

This script makes three separate connections to a sever
located on the same computer on port 9090. During the
first connection a 'GET' command is issued to receive the
current value in the server. A subsequent connection updates
the value to 0xBAADF00D and this value is read back during
the final connection.
"""

import socket

BUFFER_SIZE = 1024
SERVER_ADDR = '127.0.0.1'
SERVER_PORT = 9090

# GET current value
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
    sock.connect((SERVER_ADDR, SERVER_PORT))
    sock.send(b'GET')
    data = sock.recv(BUFFER_SIZE)
    print("Server value is:", data)

# POST a new value: BAADF00D
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
    sock.connect((SERVER_ADDR, SERVER_PORT))
    sock.send(b'POST' + bytes.fromhex('BAADF00D'))

# GET current value again
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
    sock.connect((SERVER_ADDR, SERVER_PORT))
    sock.send(b'GET')
    data = sock.recv(BUFFER_SIZE)
    print("Server value is:", data)

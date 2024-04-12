""" Simple Server Example

This script creates a socket and listens for connections
on any IPv4 interface on port 9090. When a connection is
established, the server waits for a GET or POST command.

GET:
  FORMAT: b'GET'
The server will send the current 32-bit SERVER_VALUE to the client.
  
POST:
  FORMAT: b'POST' + XXXX
The format of this command must be the four bytes corresponding
to the ASCII characters 'POST' followed immediately by four
bytes that contain the new value to set to SERVER_VALUE.
"""
import socket
import _thread

HOST = '192.168.1.11' # The IP address of the computer this script runs on (or change to 127.0.0.1 for localhost)
PORT = 22 # The port used by this TCP server 
BUFFER_SIZE = 1024
SERVER_VALUE = bytes.fromhex('DEADBEEF')

def open_new_client(connection):
    print("CONNECTION")
    global SERVER_VALUE

    # Loop until connection closed
    while True:
        # Receive and handle command
        data = connection.recv(BUFFER_SIZE)
        if len(data) == 8 and data[:4] == b'POST':
            SERVER_VALUE = data[4:8]
            print("POST VALUE:", SERVER_VALUE.hex())
        elif data == b'GET':
            connection.send(SERVER_VALUE)
            print("GET", SERVER_VALUE.hex())
        else:
            print("BAD COMMAND RECEIVED")
            break

    # Close the connection if break from loop
    connection.shutdown(1)
    connection.close()
    print("CONNECTION CLOSED")

def listen():
    # Setup the socket
    connection = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    connection.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

    # Bind to an address and port to listen on
    connection.bind((HOST, PORT))
    connection.listen(10)
    print("BEGIN LISTENING ON PORT", PORT)

    # Loop forever, accepting all connections in new thread
    while True:
        new_conn, _ = connection.accept()
        _thread.start_new_thread(open_new_client, (new_conn,))

if __name__ == "__main__":
    try:
        listen()
    except KeyboardInterrupt:
        pass

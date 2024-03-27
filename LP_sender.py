import numpy as np
import struct
import socket
import _thread

HOST = '192.168.1.11'   # IP address of External Computer
PORT = 22               # The port used by this TCP server 
BUFFER_SIZE = 1446      # Maximum workable TCP packet size

num_rows = 25
num_cols = 1034

# Dummy matrix ~ 94 MiB
tableau = np.random.rand(num_rows, num_cols)
tableau = tableau * 2000 - 1000
tableau = tableau.astype(np.float32)

print("TABLEAU SIZE: {:,} bytes\n".format(tableau.nbytes))

def open_new_client(connection):
    global tableau
    print("CONNECTION")

    # Loop until connection closed
    while True:
        # Receive and handle command
        data = connection.recv(BUFFER_SIZE)
        
        if (data != b'READY!'):
            print("Error: unknown packet from client")
            break

        #######################################################################################
        ########################### SEND TABLEAU OVER CODE BELOW ##############################
        #######################################################################################

        # Start the transfer
        print("PACKET RECEIVED. DATA: READY! Starting transfer...\n")
        
        # Send row and column info first
        connection.send(struct.pack("!II", num_rows, num_cols))

        # Send actual matrix next
        # Pack and send the matrix in chunks
        tableau = tableau.flatten()

        # Each 2892 byte wide TCP packet can only hold 723 float32 numbers
        FP_per_packet = int(BUFFER_SIZE / 4)

        for i in range(0, len(tableau), FP_per_packet):
            # Calculate the end index for the current chunk
            end_index = min(i + FP_per_packet, len(tableau))

            # Slice the flattened matrix to get the current chunk
            chunk = tableau[i:end_index]

            # Pack the chunk using struct.pack and send it over the connection
            packed_chunk = struct.pack('!{}f'.format(len(chunk)), *chunk)
            connection.send(packed_chunk)

            print("Sent {0} out of {1} packets... Data {2}".format(i // FP_per_packet + 1, (len(tableau) // FP_per_packet) + 1, end_index))

        tableau = tableau.reshape((num_rows, num_cols))

        # Print the elements in the first and last of each row
        # for j in range(0, len(tableau)):
        #     print("ROW {0} BEGINNING: {1}".format(j, tableau[j][0]))
        #     print("ROW {0} END: {1}\n".format(j, tableau[j][-1]))

        # Print the elements in last row
        # print(tableau[-1])
        # print(tableau[0][0:10])

        #######################################################################################
        ######################### RECEIVE TABLEAU BACK CODE BELOW #############################
        #######################################################################################

        # Wait until data is sent back
        RECV_BUFFER_SIZE = 64                           # Can receive 64 bytes at once
        num_elements_recvd = 0

        byte_buffer = b''
        recvd_tableau = np.array([], dtype=np.float32)  # Initialize empty tableau to hold our results

        while (1):
            # Have we received all data
            if (num_elements_recvd == num_cols * num_rows):
                break

            data_rcvd = connection.recv(RECV_BUFFER_SIZE)
            byte_buffer += data_rcvd

            # Process each 4 bytes in buffer
            while len(byte_buffer) >= 4:
                largest_multiple = (len(byte_buffer) // 4)

                floats_rcvd = struct.unpack('<{0}f'.format(largest_multiple), byte_buffer[:largest_multiple * 4])
                recvd_tableau = np.append(recvd_tableau, floats_rcvd)
                byte_buffer = byte_buffer[largest_multiple * 4:]

                num_elements_recvd += largest_multiple
                print("RECEIVED {0} ELEMENTS...".format(num_elements_recvd))

        recvd_tableau = recvd_tableau.reshape((num_rows, num_cols))
        
        # Print the elements in the first and last of each row
        # for j in range(0, len(recvd_tableau)):
        #     print("ROW {0} BEGINNING: {1}".format(j, recvd_tableau[j][0]))
        #     print("ROW {0} END: {1}\n".format(j, recvd_tableau[j][-1]))

        print("DONE")

        # VERIFICATION: check that both tableaus are equal
        if (np.all(tableau == recvd_tableau)):
            print("TABLEAUS ARE EQUAL!!!")
        else:
            print("TABLEAUS NOT EQUAL :((((((")

    # Close the connection if break from loop
    #connection.shutdown(1)
    #connection.close()
    #print("CONNECTION CLOSED")

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
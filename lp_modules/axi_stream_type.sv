parameter DATAW = 32;

typedef struct {
    logic valid;
    logic ready;
    logic [DATAW-1:0] data;
} axi_stream;

interface axi_stream_port #(int DATAW = 32);
   axi_stream port;
   
   logic valid = port.valid;
   logic [DATAW-1:0] data = port.data;
   logic ready = port.ready;

   modport in (input valid, input data, output ready);
   modport out (output valid, output data, input ready);
endinterface

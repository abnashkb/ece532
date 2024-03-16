parameter DATAW = 32;

typedef struct {
    logic valid;
    logic ready;
    logic [DATAW-1:0] data;
} axi_stream_port;

interface axi_stream #(int DATAW = 32);
   axi_stream_port port;
   
   logic valid = port.valid;
   logic [DATAW-1:0] data = port.data;
   logic ready = port.ready;

   modport in (input valid, input data, output ready);
   modport out (output valid, output data, input ready);
endinterface

import vibe.vibe;
import vibemodbus.tcp.server;


class ZeroHandler : ModbusRequestHandler
{
    void onReadCoils(const ReadCoilsRequest* req, Response* res)
    {
        res.pdu.data = [
            0x1,  // Byte count
            0x0,  // Coil Status
            ];
    }

    void onReadDiscreteInputs(const ReadDiscreteInputsRequest* req, Response* res)
    {
        res.pdu.data = [
            0x1,  // Byte count
            0x0,  // Input status
            ];
    }

    void onReadHoldingRegisters(const ReadHoldingRegistersRequest* req, Response* res)
    {
        res.pdu.data = [
            0x2,      // Byte count
            0x0, 0x1  // Register value (0x1)
            ];
    }

    void onReadInputRegisters(const ReadInputRegistersRequest* req, Response* res)
    {
        res.pdu.data = [
            0x2,     // Byte count
            0x0, 0x0 // Input Registers
            ];
    }

    void onWriteSingleCoil(const WriteSingleCoilRequest* req, Response* res)
    {
        res.pdu.data = [
            0x0, 0x0,  // Output Address
            0x0, 0x0,  // Output Value
            ];
    }

    void onWriteSingleRegister(const WriteSingleRegisterRequest* req, Response* res)
    {
        res.pdu.data = [
            0x0, 0x0,  // Register Address
            0x0, 0x0,  // Register Value
            ];
    }

    void onWriteMultipleCoils(const WriteMultipleCoilsRequest* req, Response* res)
    {
        res.pdu.data = [
            0x0, 0x0,  // Starting Address
            0x0, 0x0,  // Quantity of Output
            ];
    }

    void onWriteMultipleRegisters(const WriteMultipleRegistersRequest* req, Response* res)
    {
        res.pdu.data = [
            0x0, 0x0,  // Startng Address
            0x0, 0x0,  // Quantity of Registers
            ];
    }
}


void main()
{
    vibemodbus.tcp.server.listenTCP(ushort(40960), new ZeroHandler, "127.0.0.1");
    runApplication();
}

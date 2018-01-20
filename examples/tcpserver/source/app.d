import vibe.core.core : runApplication;
import vibemodbus.tcp.server;


class ZeroHandler : MODBUSRequestHandler
{
    void onReadCoils(ref const ReadCoilsRequest req, ref Response res) @safe
    {
        res.pdu.data = [
            0x1,  // Byte count
            0x0,  // Coil Status
            ];
    }

    void onReadDiscreteInputs(ref const ReadDiscreteInputsRequest req, ref Response res) @safe
    {
        res.pdu.data = [
            0x1,  // Byte count
            0x0,  // Input status
            ];
    }

    void onReadHoldingRegisters(ref const ReadHoldingRegistersRequest req, ref Response res)
    {
        res.pdu.data = [
            0x2,      // Byte count
            0x0, 0x1  // Register value (0x1)
            ];
    }

    void onReadInputRegisters(ref const ReadInputRegistersRequest req, ref Response res)
    {
        res.pdu.data = [
            0x2,     // Byte count
            0x0, 0x0 // Input Registers
            ];
    }

    void onWriteSingleCoil(ref const WriteSingleCoilRequest req, ref Response res)
    {
        res.pdu.data = [
            0x0, 0x0,  // Output Address
            0x0, 0x0,  // Output Value
            ];
    }

    void onWriteSingleRegister(ref const WriteSingleRegisterRequest req, ref Response res)
    {
        res.pdu.data = [
            0x0, 0x0,  // Register Address
            0x0, 0x0,  // Register Value
            ];
    }

    void onWriteMultipleCoils(ref const WriteMultipleCoilsRequest req, ref Response res)
    {
        res.pdu.data = [
            0x0, 0x0,  // Starting Address
            0x0, 0x0,  // Quantity of Output
            ];
    }

    void onWriteMultipleRegisters(ref const WriteMultipleRegistersRequest req, ref Response res)
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

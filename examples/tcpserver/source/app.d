import std.functional : toDelegate;
import std.stdio;
import vibe.vibe;
import vibemodbus.tcp.server;

void zeroHandler(const Request* req, Response* res)
{
    switch (req.pdu.functionCode)
    {
    case FunctionCode.ReadCoils:
        res.pdu.data = [
            0x1,  // Byte count
            0x0,  // Coil Status
            ];
        break;
    case FunctionCode.ReadDiscreteInputs:
        res.pdu.data = [
            0x1,  // Byte count
            0x0,  // Input status
            ];
        break;
    case FunctionCode.ReadHoldingRegisters:
        res.pdu.data = [
            0x1,  // Byte count
            0x0,  // Register value
            ];
        break;
    case FunctionCode.ReadInputRegisters:
        res.pdu.data = [
            0x2,     // Byte count
            0x0, 0x0 // Input Registers
            ];
        break;
    case FunctionCode.WriteSingleCoil:
        res.pdu.data = [
            0x0, 0x0,  // Output Address
            0x0, 0x0,  // Output Value
            ];
        break;
    case FunctionCode.WriteSingleRegister:
        res.pdu.data = [
            0x0, 0x0,  // Register Address
            0x0, 0x0,  // Register Value
            ];
        break;
    case FunctionCode.WriteMultipleCoils:
        res.pdu.data = [
            0x0, 0x0,  // Starting Address
            0x0, 0x0,  // Quantity of Output
            ];
        break;
    case FunctionCode.WriteMultipleRegisters:
        res.pdu.data = [
            0x0, 0x0,  // Starting Address
            0x0, 0x0,  // Quantity of Registers
            ];
        break;
    case FunctionCode.ReadWriteMultipleRegisters:
        res.pdu.data = [
            0x2,       // Byte Count
            0x0, 0x0,  // Read Registers value
            ];
        break;
    default:
        assert(false);
    }
}

void main()
{
    vibemodbus.tcp.server.listenTCP(ushort(40960), toDelegate(&zeroHandler), "127.0.0.1");
    runApplication();
}

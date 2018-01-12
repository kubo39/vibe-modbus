import std.functional : toDelegate;
import std.stdio;
import vibe.vibe;
import vibemodbus.tcp.server;

void zeroHandler(const Request* req, Response* res)
{
    switch (req.pdu.functionCode)
    {
    case FunctionCode.ReadCoils:
    case FunctionCode.ReadDiscreteInputs:
    case FunctionCode.ReadHoldingRegisters:
    case FunctionCode.ReadInputRegisters:
    case FunctionCode.WriteSingleCoil:
    case FunctionCode.WriteSingleRegister:
    case FunctionCode.WriteMultipleCoils:
    case FunctionCode.WriteMultipleRegisters:
    case FunctionCode.ReadWriteMultipleRegisters:
    default:
        assert(false);
    }
}

void main()
{
    vibemodbus.tcp.server.listenTCP(ushort(40960), toDelegate(&zeroHandler), "localhost");
    runApplication();
}

import std.stdio;
import vibemodbus.tcp.client;

void main()
{
    auto client = Client("localhost", 40960);
    writeln("Calling ReadHolding Registers");
    auto res = client.readHoldingRegisters(0x1000, 7);
    writeln("MBAP Header: ", res.header);
    writeln("FunctionCode: ", cast(FunctionCode) res.functionCode);
    writeln("Byte Count: ", res.byteCount);
    writeln("Register Value: ", res.registerValue);
}

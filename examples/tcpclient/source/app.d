import std.stdio;
import vibemodbus.tcp.client;

void main()
{
    auto client = Client("localhost", 40960);

    writeln("Calling Read Holding Registers");
    auto res = client.readHoldingRegisters(0x1000, 7);
    writeln("MBAP Header: ");
    writeln("  transaction id: ", res.header.transactionId);
    writeln("  protocol id: ", res.header.protocolId);
    writeln("  length: ", res.header.length);
    writeln("  unit id: ", res.header.unitId);
    writeln("FunctionCode: ", cast(FunctionCode) res.functionCode);
    writeln("Byte Count: ", res.byteCount);
    writeln("Register Value: ", res.registerValue);

    writeln("\n");

    writeln("Calling Write Single Registers");
    auto res2 = client.writeSingleRegister(0x1000, 20);
    writeln("MBAP Header: ");
    writeln("  transaction id: ", res2.header.transactionId);
    writeln("  protocol id: ", res2.header.protocolId);
    writeln("  length: ", res2.header.length);
    writeln("  unit id: ", res2.header.unitId);
    writeln("FunctionCode: ", cast(FunctionCode) res2.functionCode);
    writeln("Register Address: ", res2.registerAddress);
    writeln("Register Value: ", res2.registerValue);
}

import std.stdio;
import vibemodbus.tcp.client;

void callReadHoldingRegisters(Client client)
{
    writeln("Calling Read Holding Registers...");
    auto res = client.readHoldingRegisters(0x1000, 7);
    writeln("MBAP Header: ");
    writeln("  transaction id: ", res.header.transactionId);
    writeln("  protocol id: ", res.header.protocolId);
    writeln("  length: ", res.header.length);
    writeln("  unit id: ", res.header.unitId);
    writefln("FunctionCode: %#x", cast(FunctionCode) res.functionCode);
    writefln("Byte Count: %#x", res.byteCount);
    writefln("Register Value: [%(%#x %)]", res.registerValue);
}

void callWriteSingleRegister(Client client)
{
    writeln("Calling Write Single Register...");
    auto res = client.writeSingleRegister(0x1000, 20);
    writeln("MBAP Header: ");
    writeln("  transaction id: ", res.header.transactionId);
    writeln("  protocol id: ", res.header.protocolId);
    writeln("  length: ", res.header.length);
    writeln("  unit id: ", res.header.unitId);
    writefln("FunctionCode: %#x", cast(FunctionCode) res.functionCode);
    writefln("Register Address: %#x", res.registerAddress);
    writefln("Register Value: %#x", res.registerValue);
}

void callWriteMultipleRegisters(Client client)
{
    writeln("Calling Write Multiple Registers...");
    auto res = client.writeMultipleRegisters(0x1000, 0x20, [0x10, 0x10]);
    writeln("MBAP Header: ");
    writeln("  transaction id: ", res.header.transactionId);
    writeln("  protocol id: ", res.header.protocolId);
    writeln("  length: ", res.header.length);
    writeln("  unit id: ", res.header.unitId);
    writefln("FunctionCode: %#x", cast(FunctionCode) res.functionCode);
    writefln("Starting Address: %#x", res.startingAddress);
    writefln("Quantity of Registers: %#x", res.quantityOfRegisters);
}

void main()
{
    auto client = Client("localhost", 40960);

    client.callReadHoldingRegisters();
    writeln("\n");
    client.callWriteSingleRegister();
    writeln("\n");
    client.callWriteMultipleRegisters();
}

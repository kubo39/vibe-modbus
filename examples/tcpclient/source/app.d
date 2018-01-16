import std.algorithm : map;
import std.array : array;
import std.bitmanip : read;
import std.range : chunks;
import std.stdio;
import std.system : Endian;

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
    writefln("FunctionCode: %#x", cast(FunctionCode) res.pdu.functionCode);
    writefln("Byte Count: %#x", res.pdu.data.read!(ubyte, Endian.bigEndian));
    ushort[] registerValue = res.pdu.data.chunks(2)
        .map!(a => a.read!(ushort, Endian.bigEndian))
        .array;
    writefln("Register Value: [%(%#x %)]", registerValue);
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
    writefln("FunctionCode: %#x", cast(FunctionCode) res.pdu.functionCode);
    writefln("Register Address: %#x", res.pdu.data.read!(ushort, Endian.bigEndian));
    writefln("Register Value: %#x", res.pdu.data.read!(ushort, Endian.bigEndian));
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
    writefln("FunctionCode: %#x", cast(FunctionCode) res.pdu.functionCode);
    writefln("Starting Address: %#x", res.pdu.data.read!(ushort, Endian.bigEndian));
    writefln("Quantity of Registers: %#x", res.pdu.data.read!(ushort, Endian.bigEndian));
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

module vibemodbus.tcp.common;

import std.bitmanip : read, write;
import std.exception : enforce;
import std.system : Endian;

import vibemodbus.exception;
public import vibemodbus.protocol.common;
public import vibemodbus.protocol.tcp;

alias Request = TCPAdu;
alias Response = TCPAdu;


// Write MBAP Header fields.
void encodeMBAPHeader(ubyte[] buffer, MBAPHeader header)
{
    size_t index = 0;
    buffer.write!(ushort, Endian.bigEndian)(header.transactionId, &index);
    assert(index == 2);
    buffer.write!(ushort, Endian.bigEndian)(PROTOCOL_ID, &index);
    assert(index == 4);
    buffer.write!(ushort, Endian.bigEndian)(header.length, &index);
    assert(index == 6);
    buffer.write!(ubyte, Endian.bigEndian)(header.unitId, &index);
    assert(index == 7);
}

unittest
{
    ubyte[] buffer = new ubyte[MBAP_HEADER_LEN];
    MBAPHeader header = MBAPHeader(0x11, PROTOCOL_ID, 3, 1);
    encodeMBAPHeader(buffer, header);
    assert(buffer == [0x0, 0x11, 0x0, 0x0, 0x0, 0x3, 0x1]);
}

void encodePDU(ubyte[] buffer, Pdu pdu)
{
    buffer[0] = pdu.functionCode;
    buffer[1 .. $] = pdu.data;
}

void encodeADU(ubyte[] buffer, TCPAdu adu)
{
    encodeMBAPHeader(buffer, adu.header);
    encodePDU(buffer[MBAP_HEADER_LEN .. $], adu.pdu);
}

unittest
{
    TCPAdu adu = TCPAdu(MBAPHeader(0x11, PROTOCOL_ID, 4, 1),
                        Pdu(0x1, [0x0, 0x0]));
    ubyte[] buffer = new ubyte[MBAP_HEADER_LEN + adu.header.length - 1];
    encodeADU(buffer, adu);
    assert(buffer == [0x0, 0x11, 0x0, 0x0, 0x0, 0x4, 0x1, // MBAP Header
                      0x1, 0x0, 0x0]);
}

void decodeMBAPHeader(ref ubyte[] data, MBAPHeader* header)
{
    // Start parsing MBAP header.
    auto transactionId = data.read!(ushort, Endian.bigEndian);
    auto protocolId = data.read!(ushort, Endian.bigEndian);
    enforce!InvalidProtocolID(protocolId == PROTOCOL_ID, "Invalid Protocol ID.");

    // length = bytes of PDU + unit ID.
    auto length = data.read!(ushort, Endian.bigEndian);
    auto unitId = data.read!(ubyte, Endian.bigEndian);

    header.transactionId = transactionId;
    header.protocolId = protocolId;
    header.length = length;
    header.unitId = unitId;
}

void decodePDU(ubyte[] data, Pdu* pdu)
{
    ubyte functionCode = data[0];
    enforce!InvalidFunctionCode(functionCode < 0x80, "Invalid Function Code.");

    size_t index = 0;
    ubyte[] buffer;

    switch (functionCode) {
    case FunctionCode.ReadCoils:
    case FunctionCode.ReadDiscreteInputs:
    case FunctionCode.ReadInputRegisters:
    case FunctionCode.ReadHoldingRegisters:
    case FunctionCode.WriteSingleCoil:
    case FunctionCode.WriteSingleRegister:
    case FunctionCode.WriteMultipleCoils:
    case FunctionCode.WriteMultipleRegisters:
    case FunctionCode.ReadWriteMultipleRegisters:
        break;
    default:
        throw new UnsupportedFunctionCode("Unsupported Function Code.");
    }

    pdu.functionCode = functionCode;
    pdu.data = data[1..$];
}

unittest
{
    {
        Pdu pdu;
        ubyte[] data = [0x1, 0x0, 0x0];
        decodePDU(data, &pdu);
        assert(pdu.functionCode == FunctionCode.ReadCoils);
        assert(pdu.data == [0x0, 0x0]);
    }

    // Invalid FunctionCode
    {
        import std.exception : assertThrown;
        Pdu pdu;
        ubyte[] data = [0x0, 0x0, 0x0];
        assertThrown(decodePDU(data, &pdu));
    }
}

void decodeADU(ubyte[] buffer, TCPAdu* adu)
{
    decodeMBAPHeader(buffer, &adu.header);
    decodePDU(buffer[0 .. (adu.header.length - 1)], &adu.pdu);
}

unittest
{
    TCPAdu adu;
    ubyte[] buffer = [0x0, 0x11,  // transaction id
                      0x0, 0x0,   // protocol id
                      0x0, 0x6,   // length (unit id + length(pdu))
                      0x0,        // unit id
                      0x1,        // function code
                      0x0, 0x0, 0x0, 0x0  // data
        ];
    decodeADU(buffer, &adu);
    assert(adu.header == MBAPHeader(0x11, 0x0, 0x6, 0x0));
    assert(adu.pdu.functionCode == FunctionCode.ReadCoils);
    assert(adu.pdu.data == [0x0, 0x0, 0x0, 0x0]);
}

module vibemodbus.tcp.common;

import std.bitmanip : read, write;
import std.exception : enforce;
import std.system : Endian;

import vibemodbus.exception;
import vibemodbus.protocol.common;
import vibemodbus.protocol.tcp;

alias Request = Adu;
alias Response = Adu;


ubyte[] encodeMBAPHeader(MBAPHeader header)
{
    ubyte[] buffer;
    size_t index = 0;
    buffer.write!(ushort, Endian.bigEndian)(header.transactionId, &index);
    assert(index == 2);
    buffer.write!(ushort, Endian.bigEndian)(PROTOCOL_ID, &index);
    assert(index == 4);
    buffer.write!(ushort, Endian.bigEndian)(header.length, &index);
    assert(index == 6);
    buffer.write!(ubyte, Endian.bigEndian)(header.unitId, &index);
    assert(index == 7);
    return buffer;
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


void decodeADU(ubyte[] buffer, Adu* adu)
{
    // Start parsing MBAP header.
    auto transactionId = buffer.read!(ushort, Endian.bigEndian);
    auto protocolId = buffer.read!(ushort, Endian.bigEndian);
    enforce!InvalidProtocolID(protocolId == PROTOCOL_ID, "Invalid Protocol ID.");

    // length = bytes of PDU + unit ID.
    auto length = buffer.read!(ushort, Endian.bigEndian);
    auto unitId = buffer.read!(ubyte, Endian.bigEndian);

    adu.header.transactionId = transactionId;
    adu.header.protocolId = protocolId;
    adu.header.length = length;
    adu.header.unitId = unitId;

    decodePDU(buffer[MBAP_HEADER_LEN .. (MBAP_HEADER_LEN + length - 1)], &adu.pdu);
}

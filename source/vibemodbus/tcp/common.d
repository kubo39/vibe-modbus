module vibemodbus.tcp.common;

import std.bitmanip : read, write;
import std.system : Endian;

import vibemodbus.exception;
public import vibemodbus.protocol.common;
public import vibemodbus.protocol.tcp;

alias Request = TCPApplicationDataUnit;
alias Response = TCPApplicationDataUnit;


/**
Request type.
 */

struct ReadCoilsRequest
{
    MBAPHeader header;
    ubyte functionCode;
    ushort startingAddress;
    ushort quantityOfCoils;
}

struct ReadDiscreteInputsRequest
{
    MBAPHeader header;
    ubyte functionCode;
    ushort startingAddress;
    ushort quantityOfInputs;
}

struct ReadHoldingRegistersRequest
{
    MBAPHeader header;
    ubyte functionCode;
    ushort startingAddress;
    ushort quantityOfRegisters;
}

struct ReadInputRegistersRequest
{
    MBAPHeader header;
    ubyte functionCode;
    ushort startingAddress;
    ushort quantityOfInputRegisters;
}

struct WriteSingleCoilRequest
{
    MBAPHeader header;
    ubyte functionCode;
    ushort outputAddress;
    ushort outputValue;
}

struct WriteSingleRegisterRequest
{
    MBAPHeader header;
    ubyte functionCode;
    ushort registerAddress;
    ushort registerValue;
}

struct WriteMultipleCoilsRequest
{
    MBAPHeader header;
    ubyte functionCode;
    ushort startingAddress;
    ushort quantityOfOutputs;
    ubyte byteCount;
    ubyte[] outputsValue;
}

struct WriteMultipleRegistersRequest
{
    MBAPHeader header;
    ubyte functionCode;
    ushort startingAddress;
    ushort quantityOfRegisters;
    ubyte byteCount;
    ushort[] registersValue;
}

/**
Response type.
 */

struct ReadCoilsResponse
{
    MBAPHeader header;
    ubyte functionCode;
    ubyte byteCount;
    ubyte[] coilStatus;
}

struct ReadDiscreteInputsResponse
{
    MBAPHeader header;
    ubyte functionCode;
    ubyte byteCount;
    ubyte[] inputStatus;
}

struct ReadHoldingRegistersResponse
{
    MBAPHeader header;
    ubyte functionCode;
    ubyte byteCount;
    ushort[] registerValue;
}

struct ReadInputRegistersResponse
{
    MBAPHeader header;
    ubyte functionCode;
    ubyte byteCount;
    ushort[] inputRegisters;
}

struct WriteSingleCoilResponse
{
    MBAPHeader header;
    ubyte functionCode;
    ushort outputAddress;
    bool state;
}

struct WriteSingleRegisterResponse
{
    MBAPHeader header;
    ubyte functionCode;
    ushort registerAddress;
    ushort registerValue;
}

struct WriteMultipleCoilsResponse
{
    MBAPHeader header;
    ubyte functionCode;
    ushort startingAddress;
    ushort quantityOfOutputs;
}

struct WriteMultipleRegistersResponse
{
    MBAPHeader header;
    ubyte functionCode;
    ushort startingAddress;
    ushort quantityOfRegisters;
}


// Write MBAP Header fields.
void encodeMBAPHeader(ubyte[] buffer, MBAPHeader header)
{
    size_t index = 0;
    buffer.write!(ushort, Endian.bigEndian)(header.transactionId, &index);
    assert(index == 2);
    buffer.write!(ushort, Endian.bigEndian)(header.protocolId, &index);
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

void encodePDU(ubyte[] buffer, ProtocolDataUnit pdu)
{
    buffer[0] = pdu.functionCode;
    buffer[1 .. $] = pdu.data;
}

void encodeADU(ubyte[] buffer, TCPApplicationDataUnit adu)
{
    encodeMBAPHeader(buffer, adu.header);
    encodePDU(buffer[MBAP_HEADER_LEN .. $], adu.pdu);
}

unittest
{
    auto adu = TCPApplicationDataUnit(
        MBAPHeader(0x11, PROTOCOL_ID, 4, 1),
        ProtocolDataUnit(FunctionCode.ReadCoils, [0x0, 0x0]));
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

    // length = bytes of PDU + unit ID.
    auto length = data.read!(ushort, Endian.bigEndian);
    auto unitId = data.read!(ubyte, Endian.bigEndian);

    header.transactionId = transactionId;
    header.protocolId = protocolId;
    header.length = length;
    header.unitId = unitId;
}

void decodePDU(ubyte[] data, ProtocolDataUnit* pdu)
{
    pdu.functionCode = data[0];
    pdu.data = data[1..$];
}

unittest
{
    {
        ProtocolDataUnit pdu;
        ubyte[] data = [0x1, 0x0, 0x0];
        decodePDU(data, &pdu);
        assert(pdu.functionCode == FunctionCode.ReadCoils);
        assert(pdu.data == [0x0, 0x0]);
    }
}

void decodeADU(ubyte[] buffer, TCPApplicationDataUnit* adu)
{
    decodeMBAPHeader(buffer, &adu.header);
    decodePDU(buffer[0 .. (adu.header.length - 1)], &adu.pdu);
}

unittest
{
    TCPApplicationDataUnit adu;
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

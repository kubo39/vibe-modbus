module vibemodbus.protocol.tcp;

public import vibemodbus.protocol.common;

immutable ushort PROTOCOL_ID = 0x0;
immutable size_t MBAP_HEADER_LEN = 7;
immutable size_t MAX_TCP_APU_SIZE = 260;

enum ExceptionCode
{
    IllegalFunctionCode = ubyte(0x1),
    IllegalDataAddress = 0x2,
    IllegalDataValue = 0x3,
    ServerFailure = 0x4,
    Acknowledge = 0x5,
    ServerBusy = 0x6,
    GatewayPathUnavailable = 0xA,
    GatewayTargetDevice = 0xB,
}

struct MBAPHeader
{
    ushort transactionId;
    ushort protocolId;
    ushort length;
    ubyte unitId;
}

struct ProtocolDataUnit
{
    ubyte functionCode;
    ubyte[] data;
}

struct TCPApplicationDataUnit
{
    MBAPHeader header;
    ProtocolDataUnit pdu;
}

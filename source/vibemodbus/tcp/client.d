module vibemodbus.tcp.client;

import std.bitmanip : read, write;
import std.exception : enforce;
import std.system : Endian;

import vibe.core.net;

public import vibemodbus.exception;
public import vibemodbus.protocol.common;
public import vibemodbus.protocol.tcp;
public import vibemodbus.tcp.common;


// TODO:
struct Client
{
    string host;
    ushort port;

    this(string host, ushort port)
    {
        this.host = host;
        this.port = port;
    }

    Response request(Request req)
    {
        auto conn = connectTCP(this.host, this.port);
        scope (exit) {
            conn.finalize();
            conn.close();
        }

        ubyte[] buffer = new ubyte[MBAP_HEADER_LEN + req.header.length - 1];
        encodeADU(buffer, req);
        conn.write(buffer);
        conn.flush();

        Response res;

        // Read response data.
        ubyte[] responseHeader = new ubyte[MBAP_HEADER_LEN];
        conn.read(responseHeader);
        enforce!TooSmallADU(responseHeader.length >= MBAP_HEADER_LEN, "Too small ADU length.");
        decodeMBAPHeader(responseHeader, &res.header);

        // Read response data.
        ubyte[] responsePdu = new ubyte[res.header.length - 1];
        conn.read(responsePdu);
        decodePDU(responsePdu, &res.pdu);

        return res;
    }

    Response readCoils(ushort startingAddress, ushort quantity)
    {
        ubyte[] data = new ubyte[4];
        size_t index = 0;
        data.write!(ushort, Endian.bigEndian)(startingAddress, &index);
        assert(index == 2);
        data.write!(ushort, Endian.bigEndian)(quantity, &index);
        assert(index == 4);
        auto length = cast(ushort)(1 + 1 + data.length);
        auto req = Request(MBAPHeader(0, PROTOCOL_ID, length, 0),
                           ProtocolDataUnit(FunctionCode.ReadCoils, data));
        return request(req);
    }

    Response readDiscreteInputs(ushort startingAddress, ushort quantity)
    {
        ubyte[] data = new ubyte[4];
        size_t index = 0;
        data.write!(ushort, Endian.bigEndian)(startingAddress, &index);
        assert(index == 2);
        data.write!(ushort, Endian.bigEndian)(quantity, &index);
        assert(index == 4);
        auto length = cast(short)(1 + 1 + data.length);
        auto req = Request(MBAPHeader(0, PROTOCOL_ID, length, 0),
                           ProtocolDataUnit(FunctionCode.ReadDiscreteInputs, data));
        return request(req);
    }

    Response readHoldingRegisters(ushort startingAddress, ushort quantity)
    {
        ubyte[] data = new ubyte[4];
        size_t index = 0;
        data.write!(ushort, Endian.bigEndian)(startingAddress, &index);
        assert(index == 2);
        data.write!(ushort, Endian.bigEndian)(quantity, &index);
        assert(index == 4);
        auto length = cast(short)(1 + 1 + data.length);
        auto req = Request(MBAPHeader(0, PROTOCOL_ID, length, 0),
                           ProtocolDataUnit(FunctionCode.ReadHoldingRegisters, data));
        return request(req);
    }

    Response readInputRegisters(ushort startingAddress, ushort quantity)
    {
        ubyte[] data = new ubyte[4];
        size_t index = 0;
        data.write!(ushort, Endian.bigEndian)(startingAddress, &index);
        assert(index == 2);
        data.write!(ushort, Endian.bigEndian)(quantity, &index);
        assert(index == 4);
        auto length = cast(short)(1 + 1 + data.length);
        auto req = Request(MBAPHeader(0, PROTOCOL_ID, length, 0),
                           ProtocolDataUnit(FunctionCode.ReadInputRegisters, data));
        return request(req);
    }

    Response writeSingleCoil(ushort outputAddress, bool state)
    {
        ubyte[] data = new ubyte[4];
        size_t index = 0;
        data.write!(ushort, Endian.bigEndian)(outputAddress, &index);
        assert(index == 2);
        ushort outputValue = state ? 0xFF00 : 0x0;
        data.write!(ushort, Endian.bigEndian)(outputValue, &index);
        assert(index == 4);
        auto length = cast(short)(1 + 1 + data.length);
        auto req = Request(MBAPHeader(0, PROTOCOL_ID, length, 0),
                           ProtocolDataUnit(FunctionCode.WriteSingleCoil, data));
        return request(req);
    }

    Response writeSingleRegister(ushort registerAddress, ushort registerValue)
    {
        ubyte[] data = new ubyte[4];
        size_t index = 0;
        data.write!(ushort, Endian.bigEndian)(registerAddress, &index);
        assert(index == 2);
        data.write!(ushort, Endian.bigEndian)(registerValue, &index);
        assert(index == 4);
        auto length = cast(short)(1 + 1 + data.length);
        auto req = Request(MBAPHeader(0, PROTOCOL_ID, length, 0),
                           ProtocolDataUnit(FunctionCode.WriteSingleRegister, data));
        return request(req);
    }

    Response writeMultipleCoils(ushort startingAddress, ushort quantity, ubyte[] outputsValue)
    {
        ubyte[] data = new ubyte[5 + outputsValue.length];
        size_t index = 0;
        data.write!(ushort, Endian.bigEndian)(startingAddress, &index);
        assert(index == 2);
        data.write!(ushort, Endian.bigEndian)(quantity, &index);
        assert(index == 4);
        data[5] = cast(ubyte)(outputsValue.length / 8 + 1);
        data[6 .. $] = outputsValue;
        auto length = cast(short)(1 + 1 + data.length);
        auto req = Request(MBAPHeader(0, PROTOCOL_ID, length, 0),
                           ProtocolDataUnit(FunctionCode.WriteMultipleCoils, data));
        return request(req);
    }

    Response writeMultipleRegisters(ushort startingAddress, ushort quantity,
                                    ubyte byteCount, ubyte[] registersValue)
    {
        ubyte[] data = new ubyte[5 + registersValue.length];
        size_t index = 0;
        data.write!(ushort, Endian.bigEndian)(startingAddress, &index);
        assert(index == 2);
        data.write!(ushort, Endian.bigEndian)(quantity, &index);
        assert(index == 4);
        data ~= byteCount;
        data ~= registersValue;
        auto length = cast(short)(1 + 1 + data.length);
        auto req = Request(MBAPHeader(0, PROTOCOL_ID, length, 0),
                           ProtocolDataUnit(FunctionCode.WriteMultipleRegisters, data));
        return request(req);
    }

    Response readWriteMultipleRegisters(ushort readStartingAddress, ushort readQuantity,
                                        ushort writeStartingAddress, ushort writeQuantity,
                                        ubyte byteCount, ubyte[] registersValue)
    {
        ubyte[] data = new ubyte[9 + registersValue.length];
        size_t index = 0;
        data.write!(ushort, Endian.bigEndian)(readStartingAddress, &index);
        assert(index == 2);
        data.write!(ushort, Endian.bigEndian)(readQuantity, &index);
        assert(index == 4);
        data.write!(ushort, Endian.bigEndian)(writeStartingAddress, &index);
        assert(index == 6);
        data.write!(ushort, Endian.bigEndian)(writeQuantity, &index);
        assert(index == 8);
        data ~= byteCount;
        data ~= registersValue;
        auto length = cast(short)(1 + 1 + data.length);
        auto req = Request(MBAPHeader(0, PROTOCOL_ID, length, 0),
                           ProtocolDataUnit(FunctionCode.ReadWriteMultipleRegisters, data));
        return request(req);
    }
}

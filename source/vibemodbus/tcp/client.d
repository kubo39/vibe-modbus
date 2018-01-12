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

        ubyte[] header = new ubyte[MBAP_HEADER_LEN];
        encodeMBAPHeader(header, req.header);

        conn.write(header);
        ubyte[] pdu = new ubyte[req.header.length - 1];
        encodePDU(pdu, req.pdu);
        conn.write(pdu);

        // Send data.
        conn.flush();

        // Read response data.
        ubyte[] buffer = new ubyte[MAX_TCP_APU_SIZE];
        conn.read(buffer);
        enforce!TooSmallADU(buffer.length >= MBAP_HEADER_LEN, "Too small ADU length.");

        Response res;
        decodeADU(buffer, &res);

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
                           Pdu(FunctionCode.ReadCoils, data));
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
                           Pdu(FunctionCode.ReadDiscreteInputs, data));
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
                           Pdu(FunctionCode.ReadHoldingRegisters, data));
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
                           Pdu(FunctionCode.ReadInputRegisters, data));
        return request(req);
    }

    Response writeSingleCoil(ushort outputAddress, ushort outputValue)
    {
        ubyte[] data = new ubyte[4];
        size_t index = 0;
        data.write!(ushort, Endian.bigEndian)(outputAddress, &index);
        assert(index == 2);
        data.write!(ushort, Endian.bigEndian)(outputValue, &index);
        assert(index == 4);
        auto length = cast(short)(1 + 1 + data.length);
        auto req = Request(MBAPHeader(0, PROTOCOL_ID, length, 0),
                           Pdu(FunctionCode.WriteSingleCoil, data));
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
                           Pdu(FunctionCode.WriteSingleRegister, data));
        return request(req);
    }

    Response writeMultipleCoils(ushort startingAddress, ushort quantity,
                                ubyte byteCount, ubyte[] outputValue)
    {
        ubyte[] data = new ubyte[5 + outputValue.length];
        size_t index = 0;
        data.write!(ushort, Endian.bigEndian)(startingAddress, &index);
        assert(index == 2);
        data.write!(ushort, Endian.bigEndian)(quantity, &index);
        assert(index == 4);
        data ~= byteCount;
        data ~= outputValue;
        auto length = cast(short)(1 + 1 + data.length);
        auto req = Request(MBAPHeader(0, PROTOCOL_ID, length, 0),
                           Pdu(FunctionCode.WriteMultipleCoils, data));
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
                           Pdu(FunctionCode.WriteMultipleRegisters, data));
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
                           Pdu(FunctionCode.ReadWriteMultipleRegisters, data));
        return request(req);
    }
}

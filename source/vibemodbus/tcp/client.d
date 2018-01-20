module vibemodbus.tcp.client;

import core.atomic : atomicOp, atomicLoad;
import std.bitmanip : read, write;
import std.system : Endian;

import vibe.core.net;

public import vibemodbus.protocol.common;
public import vibemodbus.protocol.tcp;
public import vibemodbus.tcp.common;


class Client
{
    string host;
    ushort port;
    TCPConnection conn;
    shared ushort transactionId;

    this(string host, ushort port)
    {
        this.host = host;
        this.port = port;
        this.transactionId = 0;
    }

    ~this()
    {
        this.conn.finalize();
        this.conn.close();
    }

    void connect()
    {
        this.conn = connectTCP(this.host, this.port);
    }

    Response request(Request req)
    {
        ubyte[] buffer = new ubyte[MBAP_HEADER_LEN + req.header.length - 1];
        encodeADU(buffer, req);
        this.conn.write(buffer);
        this.conn.flush();

        Response res;

        // Read response data.
        ubyte[] responseHeader = new ubyte[MBAP_HEADER_LEN];
        this.conn.read(responseHeader);
        decodeMBAPHeader(responseHeader, res.header);

        // Read response data.
        ubyte[] responsePdu = new ubyte[res.header.length - 1];
        this.conn.read(responsePdu);
        decodePDU(responsePdu, res.pdu);
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
        auto req = Request(MBAPHeader(this.transactionId.atomicLoad, PROTOCOL_ID, length, 0),
                           ProtocolDataUnit(FunctionCode.ReadCoils, data));
        atomicOp!"+="(this.transactionId, 1);
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
        auto req = Request(MBAPHeader(this.transactionId.atomicLoad, PROTOCOL_ID, length, 0),
                           ProtocolDataUnit(FunctionCode.ReadDiscreteInputs, data));
        atomicOp!"+="(this.transactionId, 1);
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
        auto req = Request(MBAPHeader(this.transactionId.atomicLoad, PROTOCOL_ID, length, 0),
                           ProtocolDataUnit(FunctionCode.ReadHoldingRegisters, data));
        atomicOp!"+="(this.transactionId, 1);
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
        auto req = Request(MBAPHeader(this.transactionId.atomicLoad, PROTOCOL_ID, length, 0),
                           ProtocolDataUnit(FunctionCode.ReadInputRegisters, data));
        atomicOp!"+="(this.transactionId, 1);
        return request(req);
    }

    Response writeSingleCoil(ushort address, bool state)
    {
        ubyte[] data = new ubyte[4];
        size_t index = 0;
        data.write!(ushort, Endian.bigEndian)(address, &index);
        assert(index == 2);
        data.write!(ushort, Endian.bigEndian)(state ? 0xFF00 : 0x0, &index);
        assert(index == 4);
        auto length = cast(short)(1 + 1 + data.length);
        auto req = Request(MBAPHeader(this.transactionId.atomicLoad, PROTOCOL_ID, length, 0),
                           ProtocolDataUnit(FunctionCode.WriteSingleCoil, data));
        atomicOp!"+="(this.transactionId, 1);
        return request(req);
    }

    Response writeSingleRegister(ushort address, ushort value)
    {
        ubyte[] data = new ubyte[4];
        size_t index = 0;
        data.write!(ushort, Endian.bigEndian)(address, &index);
        assert(index == 2);
        data.write!(ushort, Endian.bigEndian)(value, &index);
        assert(index == 4);
        auto length = cast(short)(1 + 1 + data.length);
        auto req = Request(MBAPHeader(this.transactionId.atomicLoad, PROTOCOL_ID, length, 0),
                           ProtocolDataUnit(FunctionCode.WriteSingleRegister, data));
        atomicOp!"+="(this.transactionId, 1);
        return request(req);
    }

    Response writeMultipleCoils(ushort address, ushort quantity, ubyte[] outputsValue)
    {
        ubyte[] data = new ubyte[5 + outputsValue.length];
        size_t index = 0;
        data.write!(ushort, Endian.bigEndian)(address, &index);
        assert(index == 2);
        data.write!(ushort, Endian.bigEndian)(quantity, &index);
        assert(index == 4);
        data[4] = cast(ubyte)(outputsValue.length / 8 + 1);
        data[5 .. $] = outputsValue;
        auto length = cast(short)(1 + 1 + data.length);
        auto req = Request(MBAPHeader(this.transactionId.atomicLoad, PROTOCOL_ID, length, 0),
                           ProtocolDataUnit(FunctionCode.WriteMultipleCoils, data));
        atomicOp!"+="(this.transactionId, 1);
        return request(req);
    }

    Response writeMultipleRegisters(ushort address, ushort quantity, ushort[] registersValue)
    {
        ubyte[] data = new ubyte[5 + registersValue.length * 2];
        size_t index = 0;
        data.write!(ushort, Endian.bigEndian)(address, &index);
        assert(index == 2);
        data.write!(ushort, Endian.bigEndian)(quantity, &index);
        assert(index == 4);
        data[index++] = cast(ubyte)(registersValue.length * 2);
        foreach (value; registersValue)
            data.write!(ushort, Endian.bigEndian)(value, &index);
        auto length = cast(short)(1 + 1 + data.length);
        auto req = Request(MBAPHeader(this.transactionId.atomicLoad, PROTOCOL_ID, length, 0),
                           ProtocolDataUnit(FunctionCode.WriteMultipleRegisters, data));
        atomicOp!"+="(this.transactionId, 1);
        return request(req);
    }

    Response readWriteMultipleRegisters(ushort readStartingAddress, ushort readQuantity,
                                        ushort writeStartingAddress, ushort writeQuantity,
                                        ushort[] registersValue)
    {
        ubyte[] data = new ubyte[9 + registersValue.length * 2];
        size_t index = 0;
        data.write!(ushort, Endian.bigEndian)(readStartingAddress, &index);
        assert(index == 2);
        data.write!(ushort, Endian.bigEndian)(readQuantity, &index);
        assert(index == 4);
        data.write!(ushort, Endian.bigEndian)(writeStartingAddress, &index);
        assert(index == 6);
        data.write!(ushort, Endian.bigEndian)(writeQuantity, &index);
        assert(index == 8);
        data[index++] = cast(ubyte)(registersValue.length * 2);
        foreach (value; registersValue)
            data.write!(ushort, Endian.bigEndian)(value, &index);
        auto length = cast(short)(1 + 1 + data.length);
        auto req = Request(MBAPHeader(this.transactionId.atomicLoad, PROTOCOL_ID, length, 0),
                           ProtocolDataUnit(FunctionCode.ReadWriteMultipleRegisters, data));
        atomicOp!"+="(this.transactionId, 1);
        return request(req);
    }
}

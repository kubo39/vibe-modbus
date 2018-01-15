module vibemodbus.tcp.client;

import std.algorithm : map;
import std.array : array;
import std.bitmanip : read, write;
import std.exception : enforce;
import std.format : format;
import std.range : chunks;
import std.system : Endian;

import vibe.core.net;

public import vibemodbus.exception;
public import vibemodbus.protocol.common;
public import vibemodbus.protocol.tcp;
public import vibemodbus.tcp.common;


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

    ReadCoilsResponse readCoils(ushort startingAddress, ushort quantity)
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
        auto res = request(req);

        checkResponse(res, FunctionCode.ReadCoils);

        return ReadCoilsResponse(res.header, res.pdu.functionCode,
                                 res.pdu.data[0], res.pdu.data[1 .. $]);
    }

    ReadDiscreteInputsResponse readDiscreteInputs(ushort startingAddress, ushort quantity)
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
        auto res = request(req);

        checkResponse(res, FunctionCode.ReadDiscreteInputs);

        return ReadDiscreteInputsResponse(res.header, res.pdu.functionCode,
                                          res.pdu.data[0], res.pdu.data[1 .. $]);
    }

    ReadHoldingRegistersResponse readHoldingRegisters(ushort startingAddress, ushort quantity)
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
        auto res =request(req);

        checkResponse(res, FunctionCode.ReadHoldingRegisters);

        ubyte byteCount = res.pdu.data.read!(ubyte, Endian.bigEndian);
        ushort[] registerValue = res.pdu.data.chunks(2)
            .map!(a => a.read!(ushort, Endian.bigEndian))
            .array;
        return ReadHoldingRegistersResponse(res.header, res.pdu.functionCode,
                                            byteCount, registerValue);
    }

    ReadInputRegistersResponse readInputRegisters(ushort startingAddress, ushort quantity)
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
        auto res = request(req);

        checkResponse(res, FunctionCode.ReadInputRegisters);

        ubyte byteCount = res.pdu.data.read!(ubyte, Endian.bigEndian);
        ushort[] inputRegisters = res.pdu.data.chunks(2)
            .map!(a => a.read!(ushort, Endian.bigEndian))
            .array;
        return ReadInputRegistersResponse(res.header, res.pdu.functionCode,
                                          byteCount, inputRegisters);
    }

    WriteSingleCoilResponse writeSingleCoil(ushort address, bool state)
    {
        ubyte[] data = new ubyte[4];
        size_t index = 0;
        data.write!(ushort, Endian.bigEndian)(address, &index);
        assert(index == 2);
        data.write!(ushort, Endian.bigEndian)(state ? 0xFF00 : 0x0, &index);
        assert(index == 4);
        auto length = cast(short)(1 + 1 + data.length);
        auto req = Request(MBAPHeader(0, PROTOCOL_ID, length, 0),
                           ProtocolDataUnit(FunctionCode.WriteSingleCoil, data));
        auto res = request(req);

        checkResponse(res, FunctionCode.WriteSingleCoil);

        ushort outputAddress = res.pdu.data.read!(ushort, Endian.bigEndian);
        ushort outputValue = res.pdu.data.read!(ushort, Endian.bigEndian);
        return WriteSingleCoilResponse(res.header, res.pdu.functionCode,
                                       outputAddress, outputValue == 0xFF00);
    }

    WriteSingleRegisterResponse writeSingleRegister(ushort address, ushort value)
    {
        ubyte[] data = new ubyte[4];
        size_t index = 0;
        data.write!(ushort, Endian.bigEndian)(address, &index);
        assert(index == 2);
        data.write!(ushort, Endian.bigEndian)(value, &index);
        assert(index == 4);
        auto length = cast(short)(1 + 1 + data.length);
        auto req = Request(MBAPHeader(0, PROTOCOL_ID, length, 0),
                           ProtocolDataUnit(FunctionCode.WriteSingleRegister, data));
        auto res = request(req);
        ushort registerAddress = res.pdu.data.read!(ushort, Endian.bigEndian);
        ushort registerValue = res.pdu.data.read!(ushort, Endian.bigEndian);
        return WriteSingleRegisterResponse(res.header, res.pdu.functionCode,
                                           registerAddress, registerValue);
    }

    WriteMultipleCoilsResponse writeMultipleCoils(ushort address, ushort quantity, ubyte[] outputsValue)
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
        auto req = Request(MBAPHeader(0, PROTOCOL_ID, length, 0),
                           ProtocolDataUnit(FunctionCode.WriteMultipleCoils, data));
        auto res = request(req);

        checkResponse(res, FunctionCode.WriteMultipleCoils);

        ushort startingAddress = res.pdu.data.read!(ushort, Endian.bigEndian);
        ushort quantityOfOutputs = res.pdu.data.read!(ushort, Endian.bigEndian);
        return WriteMultipleCoilsResponse(res.header, res.pdu.functionCode,
                                          startingAddress, quantityOfOutputs);
    }

    WriteMultipleRegistersResponse writeMultipleRegisters(ushort address, ushort quantity, ushort[] registersValue)
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
        auto req = Request(MBAPHeader(0, PROTOCOL_ID, length, 0),
                           ProtocolDataUnit(FunctionCode.WriteMultipleRegisters, data));
        auto res = request(req);

        checkResponse(res, FunctionCode.WriteMultipleRegisters);

        ushort startingAddress = res.pdu.data.read!(ushort, Endian.bigEndian);
        ushort quantityOfRegisters = res.pdu.data.read!(ushort, Endian.bigEndian);
        return WriteMultipleRegistersResponse(res.header, res.pdu.functionCode,
                                              startingAddress, quantityOfRegisters);
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
        auto req = Request(MBAPHeader(0, PROTOCOL_ID, length, 0),
                           ProtocolDataUnit(FunctionCode.ReadWriteMultipleRegisters, data));
        auto res =request(req);
        checkResponse(res, FunctionCode.ReadWriteMultipleRegisters);
        return res;
    }
}


void checkResponse(Response res, ubyte functionCode)
{
    import std.stdio;
    writeln(res);
    if (res.header.protocolId != PROTOCOL_ID)
        throw new InvalidProtocolID(format("Invalid Protocol ID: %#x",
                                               res.header.protocolId));
    if (res.pdu.functionCode != functionCode && res.pdu.functionCode >= 0x80)
    {
        ubyte exceptionCode = res.pdu.data[0];
        if (exceptionCode == ExceptionCode.IllegalDataValue)
            throw new IllegalDataValue(format("Error Response ## functionId: %#x",
                                              res.pdu.functionCode));
        else
            throw new ErrorResponse(
                format("Error Response ## functionId: %#x  exceptionCode: %#x",
                       res.pdu.functionCode, exceptionCode));
    }
}

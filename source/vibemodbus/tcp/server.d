module vibemodbus.tcp.server;

import std.bitmanip : read, write;
import std.system : Endian;

import vibe.core.log;
import vibe.core.net;

public import vibemodbus.protocol.common;
public import vibemodbus.protocol.tcp;
public import vibemodbus.tcp.common;

void writeResponse(TCPConnection conn, ref Response res)
    @trusted {
    ubyte[] buffer = new ubyte[MBAP_HEADER_LEN + res.header.length - 1];
    encodeADU(buffer, res);
    conn.write(buffer);
    conn.flush();
}

void writeErrorResponse(TCPConnection conn, ref Response res,
                        ubyte functionCode, ubyte exceptionCode)
    @safe {
    res.pdu.functionCode = functionCode;
    res.pdu.data = [ exceptionCode ];
    // length = bytes of Error(Error Code and Exception Code) + unit ID.
    //           1 + 1 + 1 = 3 bytes.
    res.header.length = 3;
    writeResponse(conn, res);
}


interface MODBUSRequestHandler
{
    void onReadCoils(ref const ReadCoilsRequest req, ref Response res) @safe;

    void onReadDiscreteInputs(ref const ReadDiscreteInputsRequest req, ref Response res) @safe;

    void onReadHoldingRegisters(ref const ReadHoldingRegistersRequest req, ref Response res) @safe;

    void onReadInputRegisters(ref const ReadInputRegistersRequest req, ref Response res) @safe;

    void onWriteSingleCoil(ref const WriteSingleCoilRequest req, ref Response res) @safe;

    void onWriteSingleRegister(ref const WriteSingleRegisterRequest req, ref Response res) @safe;

    void onWriteMultipleCoils(ref const WriteMultipleCoilsRequest req, ref Response res) @safe;

    void onWriteMultipleRegisters(ref const WriteMultipleRegistersRequest req, ref Response res) @safe;
}


void handleMODBUSConnection(TCPConnection conn, MODBUSRequestHandler handler)
    @safe {
    conn.tcpNoDelay = true;

    while (!conn.empty)
    {
        () @trusted {
            handleRequest(conn, handler);
        } ();
    }
}

void handleRequest(TCPConnection conn, MODBUSRequestHandler handler)
    @safe {
    MBAPHeader header;
    Response res;
    ubyte[] request_allocator = new ubyte[MAX_TCP_APU_SIZE];

    try {
        conn.read(request_allocator[0 .. MBAP_HEADER_LEN]);
        () @trusted { decodeMBAPHeader(request_allocator, header); } ();
    } catch (Exception ex) {
        conn.close();
        return;
    }

    ushort length = header.length;

    // Length - UnitId
    auto requestBody = request_allocator[MBAP_HEADER_LEN .. (MBAP_HEADER_LEN + header.length - 1)];
    conn.read(requestBody);

    if (header.protocolId != PROTOCOL_ID)
    {
        conn.close();
        return;
    }

    ubyte functionCode;
    try {
        functionCode = requestBody.read!(ubyte, Endian.bigEndian);
    } catch (Exception _) {
        writeErrorResponse(conn, res, cast(ubyte)(0x0),
                           ExceptionCode.IllegalFunctionCode);
        return;
    }

    try {
        switch (functionCode)
        {
        case FunctionCode.ReadCoils:
            ushort startingAddress = requestBody.read!(ushort, Endian.bigEndian);
            ushort quantityOfCoils = requestBody.read!(ushort, Endian.bigEndian);
            auto req = ReadCoilsRequest(header, functionCode,
                                    startingAddress, quantityOfCoils);
            res.header = req.header;

            if (quantityOfCoils == 0 || quantityOfCoils > 0x7D0)
            {
                writeErrorResponse(conn, res, FunctionCode.ErrorReadCoils,
                                   ExceptionCode.IllegalDataValue);
                return;
            }
            if (startingAddress + quantityOfCoils > ushort.max)
            {
                writeErrorResponse(conn, res, FunctionCode.ErrorReadCoils,
                                   ExceptionCode.IllegalDataAddress);
                return;
            }

            res.pdu.functionCode = req.functionCode;
            handler.onReadCoils(req, res);
            break;
        case FunctionCode.ReadDiscreteInputs:
            ushort startingAddress = requestBody.read!(ushort, Endian.bigEndian);
            ushort quantityOfInputs = requestBody.read!(ushort, Endian.bigEndian);
            auto req = ReadDiscreteInputsRequest(header, functionCode,
                                                 startingAddress, quantityOfInputs);
            res.header = req.header;

            if (quantityOfInputs == 0 || quantityOfInputs > 0x7D0)
            {
                writeErrorResponse(conn, res, FunctionCode.ErrorReadDiscreteInputs,
                                   ExceptionCode.IllegalDataValue);
                return;
            }
            if (startingAddress + quantityOfInputs > ushort.max)
            {
                writeErrorResponse(conn, res, FunctionCode.ErrorReadDiscreteInputs,
                                   ExceptionCode.IllegalDataAddress);
                return;
            }

            res.pdu.functionCode = req.functionCode;
            handler.onReadDiscreteInputs(req, res);
            break;
        case FunctionCode.ReadHoldingRegisters:
            ushort startingAddress = requestBody.read!(ushort, Endian.bigEndian);
            ushort quantityOfRegisters = requestBody.read!(ushort, Endian.bigEndian);
            auto req = ReadHoldingRegistersRequest(header, functionCode,
                                                   startingAddress,
                                                   quantityOfRegisters);
            res.header = req.header;

            if (quantityOfRegisters == 0 || quantityOfRegisters > 0x7D)
            {
                writeErrorResponse(conn, res, FunctionCode.ErrorReadHoldingRegisters,
                                   ExceptionCode.IllegalDataValue);
                return;
            }
            if (startingAddress + quantityOfRegisters > ushort.max)
            {
                writeErrorResponse(conn, res, FunctionCode.ErrorReadHoldingRegisters,
                                   ExceptionCode.IllegalDataAddress);
                return;
            }

            res.pdu.functionCode = req.functionCode;
            handler.onReadHoldingRegisters(req, res);
            break;
        case FunctionCode.ReadInputRegisters:
            ushort startingAddress = requestBody.read!(ushort, Endian.bigEndian);
            ushort quantityOfInputRegisters = requestBody.read!(ushort, Endian.bigEndian);
            auto req = ReadInputRegistersRequest(header, functionCode,
                                                 startingAddress,
                                                 quantityOfInputRegisters);
            res.header = req.header;

            if (quantityOfInputRegisters == 0 || quantityOfInputRegisters > 0x7D)
            {
                writeErrorResponse(conn, res, FunctionCode.ErrorReadInputRegisters,
                                   ExceptionCode.IllegalDataValue);
                return;
            }
            if (startingAddress + quantityOfInputRegisters > ushort.max)
            {
                writeErrorResponse(conn, res, FunctionCode.ErrorReadInputRegisters,
                                   ExceptionCode.IllegalDataAddress);
                return;
            }

            res.pdu.functionCode = req.functionCode;
            handler.onReadInputRegisters(req, res);
            break;
        case FunctionCode.WriteSingleCoil:
            ushort outputAddress = requestBody.read!(ushort, Endian.bigEndian);
            ushort outputValue = requestBody.read!(ushort, Endian.bigEndian);
            auto req = WriteSingleCoilRequest(header, functionCode,
                                              outputAddress, outputValue);
            res.header = req.header;

            if (outputValue != 0 || outputValue != 0xFF00)
            {
                writeErrorResponse(conn, res, FunctionCode.ErrorWriteSingleCoil,
                                   ExceptionCode.IllegalDataValue);
                return;
            }

            res.pdu.functionCode = req.functionCode;
            handler.onWriteSingleCoil(req, res);
            break;
        case FunctionCode.WriteSingleRegister:
            ushort registerAddress = requestBody.read!(ushort, Endian.bigEndian);
            ushort registerValue = requestBody.read!(ushort, Endian.bigEndian);
            auto req = WriteSingleRegisterRequest(header, functionCode,
                                                  registerAddress, registerValue);
            res.header = req.header;
            res.pdu.functionCode = req.functionCode;
            handler.onWriteSingleRegister(req, res);
            break;
        case FunctionCode.WriteMultipleCoils:
            ushort startingAddress = requestBody.read!(ushort, Endian.bigEndian);
            ushort quantityOfOutputs = requestBody.read!(ushort, Endian.bigEndian);
            ubyte byteCount = requestBody.read!(ubyte, Endian.bigEndian);
            ubyte[] outputsValue = requestBody.dup;
            auto req = WriteMultipleCoilsRequest(header, functionCode,
                                                 startingAddress, quantityOfOutputs,
                                                 byteCount, outputsValue);
            res.header = req.header;

            if (quantityOfOutputs == 0 || quantityOfOutputs > 0x7B0)
            {
                writeErrorResponse(conn, res, FunctionCode.ErrorWriteMultipleCoils,
                                   ExceptionCode.IllegalDataValue);
                return;
            }
            if (startingAddress + quantityOfOutputs > ushort.max)
            {
                writeErrorResponse(conn, res, FunctionCode.ErrorWriteMultipleCoils,
                                   ExceptionCode.IllegalDataAddress);
                return;
            }

            res.pdu.functionCode = req.functionCode;
            handler.onWriteMultipleCoils(req, res);
            break;
        case FunctionCode.WriteMultipleRegisters:
            ushort startingAddress = requestBody.read!(ushort, Endian.bigEndian);
            ushort quantityOfRegisters = requestBody.read!(ushort, Endian.bigEndian);
            ubyte byteCount = requestBody.read!(ubyte, Endian.bigEndian);

            if (quantityOfRegisters == 0x0 || quantityOfRegisters > 0x7B
                || byteCount % 2 != 0)
            {
                writeErrorResponse(conn, res,
                                   FunctionCode.ErrorWriteMultipleRegisters,
                                   ExceptionCode.IllegalDataValue);
                return;
            }
            if (startingAddress + quantityOfRegisters > ushort.max)
            {
                writeErrorResponse(conn, res,
                                   FunctionCode.ErrorWriteMultipleRegisters,
                                   ExceptionCode.IllegalDataAddress);
                return;
            }

            ushort[] registersValue = new ushort[(header.length - 7) / 2];
            while (requestBody.length)
                registersValue ~= requestBody.read!(ushort, Endian.bigEndian);

            auto req = WriteMultipleRegistersRequest(header, functionCode,
                                                     startingAddress,
                                                     quantityOfRegisters,
                                                     byteCount,
                                                     registersValue);

            res.header = req.header;

            if (req.quantityOfRegisters == 0 || req.quantityOfRegisters > 0x7B)
            {
                writeErrorResponse(conn, res, FunctionCode.ErrorWriteMultipleRegisters,
                                   ExceptionCode.IllegalDataValue);
                return;
            }

            res.pdu.functionCode = req.functionCode;
            handler.onWriteMultipleRegisters(req, res);
            break;
        case FunctionCode.ReadWriteMultipleRegisters:

            // Unsupported Function Code.
        case 0x7: .. case 0xE:
        case 0x11: .. case 0x16:
        case 0x18: .. case 0x79:
            writeErrorResponse(conn, res, cast(ubyte)(functionCode + 0x80),
                               ExceptionCode.IllegalFunctionCode);
            return;
        default: // == 0x0 or >= 0x80
            writeErrorResponse(conn, res, functionCode,
                               ExceptionCode.IllegalFunctionCode);
            return;
        }
    }
    catch (Exception ex)
    {
        writeErrorResponse(conn, res, functionCode,
                           ExceptionCode.ServerFailure);
    }

    // length = bytes of PDU(Function Code and Data) + unit ID.
    res.header.length = cast(ushort)(res.pdu.data.length + 1 + 1);

    writeResponse(conn, res);
}

TCPListener listenTCP(ushort port, MODBUSRequestHandler handler, string address)
{
    return vibe.core.net.listenTCP(port, (conn) @safe nothrow {
            try handleMODBUSConnection(conn, handler);
            catch (Exception e) {
                debug logDebug("Full error: %s", () @trusted { return e.toString(); } ());
                try conn.close();
                catch (Exception e) logError("Failed to close connection: %s", e.msg);
            }
        }, address);
}


shared static this()
{
    import core.sys.posix.signal;
    assert(signal(SIGPIPE, SIG_IGN) != SIG_ERR);
}

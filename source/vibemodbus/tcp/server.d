module vibemodbus.tcp.server;

import std.bitmanip : read, write;
import std.system : Endian;

import vibe.core.net;

public import vibemodbus.exception;
public import vibemodbus.protocol.common;
public import vibemodbus.protocol.tcp;
public import vibemodbus.tcp.common;


void encodeResponse(TCPConnection conn, Response* res)
{
    ubyte[] buffer = new ubyte[MBAP_HEADER_LEN + res.header.length - 1];
    encodeADU(buffer, *res);
    conn.write(buffer);
    conn.finalize();
}

void encodeErrorResponse(TCPConnection conn, Response* res,
                         ubyte functionCode, ubyte exceptionCode)
{
    res.pdu.functionCode = functionCode;
    res.pdu.data = [ exceptionCode ];
    // length = bytes of Error(Error Code and Exception Code) + unit ID.
    //           1 + 1 + 1 = 3 bytes.
    res.header.length = 3;
    encodeResponse(conn, res);
}


interface ModbusRequestHandler
{
    void onReadCoils(const ReadCoilsRequest* req, Response* res);

    void onReadDiscreteInputs(const ReadDiscreteInputsRequest* req, Response* res);

    void onReadHoldingRegisters(const ReadHoldingRegistersRequest* req, Response* res);

    void onReadInputRegisters(const ReadInputRegistersRequest* req, Response* res);

    void onWriteSingleCoil(const WriteSingleCoilRequest* req, Response* res);

    void onWriteSingleRegister(const WriteSingleRegisterRequest* req, Response* res);

    void onWriteMultipleCoils(const WriteMultipleCoilsRequest* req, Response* res);

    void onWriteMultipleRegisters(const WriteMultipleRegistersRequest* req, Response* res);
}


TCPListener listenTCP(ushort port, ModbusRequestHandler handler, string address)
{
    return vibe.core.net.listenTCP(port, (TCPConnection conn) {
            MBAPHeader header;
            Response res;

            ubyte[] buffer1 = new ubyte[MBAP_HEADER_LEN];
            conn.read(buffer1);

            decodeMBAPHeader(buffer1, &header);
            ushort length = header.length;
            ubyte[] buffer2 = new ubyte[header.length - 1]; // Length - UnitId
            conn.read(buffer2);

            ubyte functionCode = buffer2.read!(ubyte, Endian.bigEndian);

            if (header.protocolId != PROTOCOL_ID)
            {
                encodeErrorResponse(conn, &res, cast(ubyte)(functionCode + 0x80),
                                    ExceptionCode.IllegalDataValue);
                return;
            }

            switch (functionCode)
            {
            case FunctionCode.ReadCoils:
                ushort startingAddress = buffer2.read!(ushort, Endian.bigEndian);
                ushort quantityOfCoils = buffer2.read!(ushort, Endian.bigEndian);
                auto req = ReadCoilsRequest(header, functionCode,
                                            startingAddress, quantityOfCoils);
                res.header = req.header;

                if (req.quantityOfCoils == 0 || req.quantityOfCoils > 0x7D0)
                {
                    encodeErrorResponse(conn, &res, FunctionCode.ErrorReadCoils,
                                        ExceptionCode.IllegalDataValue);
                    return;
                }

                res.pdu.functionCode = req.functionCode;
                handler.onReadCoils(&req, &res);
                break;
            case FunctionCode.ReadDiscreteInputs:
                ushort startingAddress = buffer2.read!(ushort, Endian.bigEndian);
                ushort quantityOfInputs = buffer2.read!(ushort, Endian.bigEndian);
                auto req = ReadDiscreteInputsRequest(header, functionCode,
                                                     startingAddress, quantityOfInputs);
                res.header = req.header;

                if (req.quantityOfInputs == 0 || req.quantityOfInputs > 0x7D0)
                {
                    encodeErrorResponse(conn, &res, FunctionCode.ErrorReadDiscreteInputs,
                                        ExceptionCode.IllegalDataValue);
                    return;
                }

                res.pdu.functionCode = req.functionCode;
                handler.onReadDiscreteInputs(&req, &res);
                break;
            case FunctionCode.ReadHoldingRegisters:
                ushort startingAddress = buffer2.read!(ushort, Endian.bigEndian);
                ushort quantityOfRegisters = buffer2.read!(ushort, Endian.bigEndian);
                auto req = ReadHoldingRegistersRequest(header, functionCode,
                                                       startingAddress,
                                                       quantityOfRegisters);
                res.header = req.header;

                if (req.quantityOfRegisters == 0 || req.quantityOfRegisters > 0x7D)
                {
                    encodeErrorResponse(conn, &res, FunctionCode.ErrorReadHoldingRegisters,
                                        ExceptionCode.IllegalDataValue);
                    return;
                }

                res.pdu.functionCode = req.functionCode;
                handler.onReadHoldingRegisters(&req, &res);
                break;
            case FunctionCode.ReadInputRegisters:
                ushort startingAddress = buffer2.read!(ushort, Endian.bigEndian);
                ushort quantityOfInputRegisters = buffer2.read!(ushort, Endian.bigEndian);
                auto req = ReadInputRegistersRequest(header, functionCode,
                                                     startingAddress,
                                                     quantityOfInputRegisters);
                res.header = req.header;

                if (req.quantityOfInputRegisters == 0 || req.quantityOfInputRegisters > 0x7D)
                {
                    encodeErrorResponse(conn, &res, FunctionCode.ErrorReadInputRegisters,
                                        ExceptionCode.IllegalDataValue);
                    return;
                }

                res.pdu.functionCode = req.functionCode;
                handler.onReadInputRegisters(&req, &res);
                break;
            case FunctionCode.WriteSingleCoil:
                ushort outputAddress = buffer2.read!(ushort, Endian.bigEndian);
                ushort outputValue = buffer2.read!(ushort, Endian.bigEndian);
                auto req = WriteSingleCoilRequest(header, functionCode,
                                                  outputAddress, outputValue);
                res.header = req.header;

                if (req.outputValue != 0 || req.outputValue != 0xFF00)
                {
                    encodeErrorResponse(conn, &res, FunctionCode.ErrorWriteSingleCoil,
                                        ExceptionCode.IllegalDataValue);
                    return;
                }

                res.pdu.functionCode = req.functionCode;
                handler.onWriteSingleCoil(&req, &res);
                break;
            case FunctionCode.WriteSingleRegister:
                ushort registerAddress = buffer2.read!(ushort, Endian.bigEndian);
                ushort registerValue = buffer2.read!(ushort, Endian.bigEndian);
                auto req = WriteSingleRegisterRequest(header, functionCode,
                                                      registerAddress, registerValue);
                res.header = req.header;
                res.pdu.functionCode = req.functionCode;
                handler.onWriteSingleRegister(&req, &res);
                break;
            case FunctionCode.WriteMultipleCoils:
                ushort startingAddress = buffer2.read!(ushort, Endian.bigEndian);
                ushort quantityOfOutputs = buffer2.read!(ushort, Endian.bigEndian);
                ubyte byteCount = buffer2.read!(ubyte, Endian.bigEndian);
                ubyte[] outputsValue = buffer2.dup;
                auto req = WriteMultipleCoilsRequest(header, functionCode,
                                                     startingAddress, quantityOfOutputs,
                                                     byteCount, outputsValue);
                res.header = req.header;

                if (req.quantityOfOutputs == 0 || req.quantityOfOutputs > 0x7B0)
                {
                    encodeErrorResponse(conn, &res, FunctionCode.ErrorWriteMultipleCoils,
                                        ExceptionCode.IllegalDataValue);
                    return;
                }

                res.pdu.functionCode = req.functionCode;
                handler.onWriteMultipleCoils(&req, &res);
                break;
            case FunctionCode.WriteMultipleRegisters:
                ushort startingAddress = buffer2.read!(ushort, Endian.bigEndian);
                ushort quantityOfRegisters = buffer2.read!(ushort, Endian.bigEndian);
                ubyte byteCount = buffer2.read!(ubyte, Endian.bigEndian);

                ushort[] registersValue = new ushort[(header.length - 7) / 2];
                while (buffer2.length)
                    registersValue ~= buffer2.read!(ushort, Endian.bigEndian);

                auto req = WriteMultipleRegistersRequest(header, functionCode,
                                                         startingAddress,
                                                         quantityOfRegisters,
                                                         byteCount,
                                                         registersValue);

                res.header = req.header;

                if (req.quantityOfRegisters == 0 || req.quantityOfRegisters > 0x7B)
                {
                    encodeErrorResponse(conn, &res, FunctionCode.ErrorWriteMultipleRegisters,
                                        ExceptionCode.IllegalDataValue);
                    return;
                }

                res.pdu.functionCode = req.functionCode;
                handler.onWriteMultipleRegisters(&req, &res);
                break;
            case FunctionCode.ReadWriteMultipleRegisters:

                 // Unsupported Function Code.
            case 0x7: .. case 0xE:
            case 0x11: .. case 0x16:
            case 0x18: .. case 0x79:
                encodeErrorResponse(conn, &res, cast(ubyte)(functionCode + 0x80),
                                    ExceptionCode.IllegalFunctionCode);
                return;
            default: // == 0x0 or >= 0x80
                encodeErrorResponse(conn, &res, functionCode,
                                    ExceptionCode.IllegalFunctionCode);
                return;
            }

            // length = bytes of PDU(Function Code and Data) + unit ID.
            res.header.length = cast(ushort)(res.pdu.data.length + 1 + 1);

            encodeResponse(conn, &res);
        }, address);
}

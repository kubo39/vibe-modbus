module vibemodbus.tcp.server;

import std.bitmanip : read, write;
import std.exception : enforce;
import std.system : Endian;

import vibe.core.net;

public import vibemodbus.exception;
public import vibemodbus.protocol.common;
public import vibemodbus.protocol.tcp;
public import vibemodbus.tcp.common;


void encodeResponse(TCPConnection conn, Response res)
{
    ubyte[] buffer = new ubyte[MBAP_HEADER_LEN + res.header.length - 1];
    encodeADU(buffer, res);
    conn.write(buffer);
    conn.finalize();
}


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
    ushort quantityOfInput;
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
    ushort quantityOfAddress;
    ubyte byteCount;
    ushort[] registersValue;
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
            ubyte[] buffer2 = new ubyte[header.length - 1];
                conn.read(buffer2);
            ubyte functionCode = buffer2[0];

            switch (functionCode)
            {
            case FunctionCode.ReadCoils:
                ReadCoilsRequest req;
                req.header = header;
                req.functionCode = buffer2.read!(ubyte, Endian.bigEndian);
                req.startingAddress = buffer2.read!(ushort, Endian.bigEndian);
                req.quantityOfCoils = buffer2.read!(ushort, Endian.bigEndian);
                res.header = req.header;
                res.pdu.functionCode = req.functionCode;
                handler.onReadCoils(&req, &res);
                break;
            case FunctionCode.ReadDiscreteInputs:
                ReadDiscreteInputsRequest req;
                req.header = header;
                req.functionCode = buffer2.read!(ubyte, Endian.bigEndian);
                req.startingAddress = buffer2.read!(ushort, Endian.bigEndian);
                req.quantityOfInput = buffer2.read!(ushort, Endian.bigEndian);
                res.header = req.header;
                res.pdu.functionCode = req.functionCode;
                handler.onReadDiscreteInputs(&req, &res);
                break;
            case FunctionCode.ReadInputRegisters:
                ReadInputRegistersRequest req;
                req.header = header;
                req.functionCode = buffer2.read!(ubyte, Endian.bigEndian);
                req.startingAddress = buffer2.read!(ushort, Endian.bigEndian);
                req.quantityOfInputRegisters = buffer2.read!(ushort, Endian.bigEndian);
                res.header = req.header;
                res.pdu.functionCode = req.functionCode;
                handler.onReadInputRegisters(&req, &res);
                break;
            case FunctionCode.ReadHoldingRegisters:
                ReadHoldingRegistersRequest req;
                req.header = header;
                req.functionCode = buffer2.read!(ubyte, Endian.bigEndian);
                req.startingAddress = buffer2.read!(ushort, Endian.bigEndian);
                req.quantityOfRegisters = buffer2.read!(ushort, Endian.bigEndian);
                res.header = req.header;
                res.pdu.functionCode = req.functionCode;
                handler.onReadHoldingRegisters(&req, &res);
                break;
            case FunctionCode.WriteSingleCoil:
                WriteSingleCoilRequest req;
                req.header = header;
                req.functionCode = buffer2.read!(ubyte, Endian.bigEndian);
                req.outputAddress = buffer2.read!(ushort, Endian.bigEndian);
                req.outputValue = buffer2.read!(ushort, Endian.bigEndian);
                res.header = req.header;
                res.pdu.functionCode = req.functionCode;
                handler.onWriteSingleCoil(&req, &res);
                break;
            case FunctionCode.WriteSingleRegister:
                WriteSingleRegisterRequest req;
                req.header = header;
                req.functionCode = buffer2.read!(ubyte, Endian.bigEndian);
                req.registerAddress = buffer2.read!(ushort, Endian.bigEndian);
                req.registerValue = buffer2.read!(ushort, Endian.bigEndian);
                res.header = req.header;
                res.pdu.functionCode = req.functionCode;
                handler.onWriteSingleRegister(&req, &res);
                break;
            case FunctionCode.WriteMultipleCoils:
                WriteMultipleCoilsRequest req;
                req.header = header;
                req.functionCode = buffer2.read!(ubyte, Endian.bigEndian);
                req.startingAddress = buffer2.read!(ushort, Endian.bigEndian);
                req.quantityOfAddress = buffer2.read!(ushort, Endian.bigEndian);
                req.byteCount = buffer2.read!(ubyte, Endian.bigEndian);

                ushort[] registersValue = new ushort[(header.length - 7) / 2];
                while (buffer2.length)
                {
                    registersValue ~= buffer2.read!(ushort, Endian.bigEndian);
                }
                req.registersValue = registersValue;

                res.header = req.header;
                res.pdu.functionCode = req.functionCode;
                handler.onWriteMultipleCoils(&req, &res);
                break;
            case FunctionCode.WriteMultipleRegisters:
            case FunctionCode.ReadWriteMultipleRegisters:

                 // Unsupported Function Code.
            case 0x7: .. case 0xE:
            case 0x11: .. case 0x16:
            case 0x18: .. case 0x79:
                break;

            default: // == 0x0 or >= 0x80
                res.pdu.data = [ ExceptionCode.IllegalFunctionCode ];
                // length = bytes of Error(Error Code and Exception Code) + unit ID.
                //           1 + 1 + 1 = 3 bytes.
                res.header.length = 3;
                encodeResponse(conn, res);
                return;
            }

            // length = bytes of PDU(Function Code and Data) + unit ID.
            res.header.length = cast(ushort)(res.pdu.data.length + 1 + 1);

            encodeResponse(conn, res);
        }, address);
}

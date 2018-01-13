module vibemodbus.tcp.server;

import std.bitmanip : read, write;
import std.exception : enforce;
import std.system : Endian;

import vibe.core.net;

public import vibemodbus.exception;
public import vibemodbus.protocol.common;
public import vibemodbus.protocol.tcp;
public import vibemodbus.tcp.common;

Request decodeRequest(ref ubyte[] buffer)
{
    Request req;
    decodeADU(buffer, &req);
    return req;
}

void encodeResponse(TCPConnection conn, Response res)
{
    ubyte[] buffer = new ubyte[MBAP_HEADER_LEN + res.header.length - 1];
    encodeADU(buffer, res);
    conn.write(buffer);
    conn.finalize();
}

TCPListener listenTCP(ushort port, void delegate(const Request*, Response*) del,
                      string address)
{
    return vibe.core.net.listenTCP(port, (TCPConnection conn) {
            Request req;
            Response res;

            ubyte[] buffer1 = new ubyte[MBAP_HEADER_LEN];
            conn.read(buffer1);

            decodeMBAPHeader(buffer1, &req.header);
            ubyte[] buffer2 = new ubyte[req.header.length - 1];
            conn.read(buffer2);
            decodePDU(buffer2, &req.pdu);

            res.header = req.header;
            res.pdu.functionCode = req.pdu.functionCode;

            if (req.pdu.functionCode == 0x0 || req.pdu.functionCode >= 0x80)
            {
                res.pdu.data = [ ExceptionCode.IllegalFunctionCode ];
                // length = bytes of Error(Error Code and Exception Code) + unit ID.
                //           1 + 1 + 1 = 3 bytes.
                res.header.length = 3;
                encodeResponse(conn, res);
                return;
            }

            if (del !is null) del(&req, &res);

            // length = bytes of PDU(Function Code and Data) + unit ID.
            res.header.length = cast(ushort)(res.pdu.data.length + 1 + 1);

            encodeResponse(conn, res);
        }, address);
}

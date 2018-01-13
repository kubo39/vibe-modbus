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

            ubyte[] buffer1 = new ubyte[MBAP_HEADER_LEN];
            conn.read(buffer1);

            decodeMBAPHeader(buffer1, &req.header);
            ubyte[] buffer2 = new ubyte[req.header.length - 1];
            conn.read(buffer2);
            decodePDU(buffer2, &req.pdu);

            // stream data size > MAX_TCP_APU_SIZE or data-length is longer than
            // length field.

            // if (!conn.empty)
            //     throw new TooSmallADU("Too small ADU.");

            Response res;
            res.header = req.header;
            res.pdu.functionCode = req.pdu.functionCode;

            if (del !is null) del(&req, &res);

            // length = bytes of PDU(Function Code and Data) + unit ID.
            res.header.length = cast(ushort)(res.pdu.data.length + 1 + 1);

            encodeResponse(conn, res);
        }, address);
}

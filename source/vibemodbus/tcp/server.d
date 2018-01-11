module vibemodbus.tcp.server;

import std.bitmanip : read, write;
import std.exception : enforce;
import std.system : Endian;

import vibe.core.net;

import vibemodbus.exception;
import vibemodbus.protocol.common;
import vibemodbus.protocol.tcp;
import vibemodbus.tcp.common;

Request decodeRequest(TCPConnection conn)
{
    Request req;
    ubyte[] buffer;

    conn.read(buffer);
    enforce!TooSmallADU(buffer.length >= MBAP_HEADER_LEN, "Too small ADU length.");
    decodeADU(buffer, &req);
    return req;
}

void encodeResponse(TCPConnection conn, const Response* res)
{
    // Write MBAP Header fields.
    auto header = encodeMBAPHeader(res.header);
    conn.write(header);

    // Write PDU.
    conn.write([res.pdu.functionCode]);
    conn.write(res.pdu.data);

    // Send data.
    conn.flush();
}

TCPListener listenTCP(ushort port, void delegate(Request*, Response*) del,
                      string address)
{
    return vibe.core.net.listenTCP(port, (TCPConnection conn) {
            auto req = decodeRequest(conn);

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

            encodeResponse(conn, &res);
        }, address);
}

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
    ubyte[] buffer;

    conn.read(buffer);
    enforce!TooSmallADU(buffer.length >= MBAP_HEADER_LEN, "Too small ADU length.");

    // Start parsing MBAP header.
    auto transactionId = buffer.read!(ushort, Endian.bigEndian);
    auto protocolId = buffer.read!(ushort, Endian.bigEndian);
    enforce!InvalidProtocolID(protocolId == PROTOCOL_ID, "Invalid Protocol ID.");

    // length = bytes of PDU + unit ID.
    auto length = buffer.read!(ushort, Endian.bigEndian);
    auto unitId = buffer.read!(ubyte, Endian.bigEndian);

    Request req;
    req.header.transactionId = transactionId;
    req.header.protocolId = protocolId;
    req.header.length = length;
    req.header.unitId = unitId;

    decodePDU(buffer[MBAP_HEADER_LEN .. (MBAP_HEADER_LEN + length - 1)], &req.pdu);
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

void listen(ushort port, string address,
            void delegate(Request*, Response*) del = null)
{
    auto listener = listenTCP(port, (TCPConnection conn) {
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

module vibemodbus.tcp.client;

import std.bitmanip : read, write;
import std.exception : enforce;
import std.system : Endian;

import vibe.core.net;

import vibemodbus.exception;
import vibemodbus.protocol.common;
import vibemodbus.protocol.tcp;
import vibemodbus.tcp.common;


// TODO:
Response request(NetworkAddress addr, Request req)
{
    auto conn = connectTCP(addr);

    // Write MBAP Header fields.
    ubyte[] header = encodeMBAPHeader(req.header);
    conn.write(header);

    // Write PDU.
    conn.write([req.pdu.functionCode]);
    conn.write(req.pdu.data);

    // Send data.
    conn.flush();

    // Read response data.
    ubyte[] buffer;
    conn.read(buffer);
    enforce!TooSmallADU(buffer.length >= MBAP_HEADER_LEN, "Too small ADU length.");

    Response res;
    decodeADU(buffer, &res);
    return res;
}

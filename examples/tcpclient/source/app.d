import std.stdio;
import vibemodbus.tcp.client;

void main()
{
    auto client = Client("localhost", 40960);
    auto res = client.readHoldingRegisters(0x1000, 7);
    writeln(res);
}

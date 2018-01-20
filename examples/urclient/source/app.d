import std.bitmanip : read;
import std.stdio;
import std.system : Endian;

import vibemodbus.tcp.client;

ushort controllerVersion(Client client)
{
    auto res = client.readHoldingRegisters(256, 1);
    ubyte _ = res.pdu.data.read!(ubyte, Endian.bigEndian);
    return res.pdu.data.read!(ushort, Endian.bigEndian);
}

string robotMode(Client client)
{
    auto res = client.readHoldingRegisters(258, 1);
    ubyte _ = res.pdu.data.read!(ubyte, Endian.bigEndian);
    ushort robotMode = res.pdu.data.read!(ushort, Endian.bigEndian);
    switch (robotMode)
    {
    case 0: return "Disconnected";
    case 1: return "Confirm_safety";
    case 2: return "Bootingz";
    case 3: return "Power_off";
    case 4: return "Power_on";
    case 5: return "Idle";
    case 6: return "Backdrive";
    case 7: return "Running";
    default: assert(false);
    }
}

bool isPowerOnRobot(Client client)
{
    auto res = client.readCoils(260, 1);
    ubyte _ = res.pdu.data.read!(ubyte, Endian.bigEndian);
    return res.pdu.data.read!(ubyte, Endian.bigEndian) == 1;
}

bool isEmergencyStopped(Client client)
{
    auto res = client.readCoils(262, 1);
    ubyte _ = res.pdu.data.read!(ubyte, Endian.bigEndian);
    return res.pdu.data.read!(ubyte, Endian.bigEndian) == 1;
}

ushort baseJointAngle(Client client)
{
    auto res = client.readHoldingRegisters(280, 1);
    ubyte _ = res.pdu.data.read!(ubyte, Endian.bigEndian);
    return res.pdu.data.read!(ushort, Endian.bigEndian);
}

void main()
{
    auto client = new Client("192.168.1.110", 502);
    client.connect();
    writeln("Controller Version: ", client.controllerVersion);
    writeln("RobotMode: ", client.robotMode);
    writeln("Is PowerOn Robot?: ", client.isPowerOnRobot);
    writeln("Is EmergencyStopped?: ", client.isEmergencyStopped);
    writeln("BaseJointAngle: ", client.baseJointAngle);
}

module vibemodbus.protocol.common;

enum FunctionCode
{
    ReadCoils = ubyte(0x1),
    ReadDiscreteInputs = 0x2,
    ReadHoldingRegisters = 0x3,
    ReadInputRegisters = 0x4,
    WriteSingleCoil = 0x5,
    WriteSingleRegister = 0x6,
    WriteMultipleCoils = 0xF,
    WriteMultipleRegisters = 0x10,
    ReadWriteMultipleRegisters = 0x17,
}

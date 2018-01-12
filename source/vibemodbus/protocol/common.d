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

    // Error Code
    ErrorReadCoils = ReadCoils + 0x80,
    ErrorReadDiscreteInputs = ReadDiscreteInputs + 0x80,
    ErrorReadHoldingRegisters = ReadHoldingRegisters + 0x80,
    ErrorReadInputRegisters = ReadInputRegisters + 0x80,
    ErrorWriteSingleCoil = WriteSingleCoil + 0x80,
    ErrorWriteSingleRegister = WriteSingleRegister + 0x80,
    ErrorWriteMultipleCoils = WriteMultipleCoils + 0x80,
    ErrorWriteMultipleRegisters = WriteMultipleRegisters + 0x80,
    ErrorReadWriteMultipleRegisters = ReadWriteMultipleRegisters + 0x80,
}

module vibemodbus.exception;

import std.exception : basicExceptionCtors, Exception;

class TooSmallADU : Exception
{
    mixin basicExceptionCtors;
}

class InvalidProtocolID : Exception
{
    mixin basicExceptionCtors;
}

class InvalidFunctionCode : Exception
{
    mixin basicExceptionCtors;
}

class UnsupportedFunctionCode : Exception
{
    mixin basicExceptionCtors;
}

class ErrorResponse : Exception
{
    mixin basicExceptionCtors;
}

class IllegalDataValue : Exception
{
    mixin basicExceptionCtors;
}

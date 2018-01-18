module vibemodbus.exception;

import std.exception : basicExceptionCtors, Exception;

class TooSmallADU : Exception
{
    mixin basicExceptionCtors;
}

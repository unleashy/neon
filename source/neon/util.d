module neon.util;

@safe:

final class NeonException : Exception
{
    import std.exception : basicExceptionCtors;
    mixin basicExceptionCtors;
}

T enforceSDL(T)(
    T result,
    in string file = __FILE__,
    in size_t line = __LINE__) @trusted
{
    import std.conv      : text;
    import std.exception : enforce;
    import std.string    : fromStringz;
    import bindbc.sdl    : SDL_GetError;

    return enforce!NeonException(
        result,
        text("SDL error: ", fromStringz(SDL_GetError())),
        file,
        line
    );
}

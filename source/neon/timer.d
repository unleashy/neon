module neon.timer;

import core.time : Duration;

final class Timer
{
    alias Fun = void delegate();

    private struct Handler
    {
        enum Type
        {
            After,
            During,
            Every,
        }

        Type type;
        Fun fun;

        long currentMs;
        long limitMs;

        uint count;

        bool infinite() @property @nogc const nothrow pure
        {
            return count == 0;
        }
    }

    private Handler[] handlers_;

    size_t after(in Duration delay, Fun fun)
    {
        handlers_ ~= Handler(
            Handler.Type.After,
            fun,
            0,
            delay.total!"msecs",
            1
        );

        return handlers_.length;
    }

    size_t every(in Duration delay, Fun fun, in uint count = 0)
    {
        handlers_ ~= Handler(
            Handler.Type.Every,
            fun,
            0,
            delay.total!"msecs",
            count
        );

        return handlers_.length;
    }

    size_t during(in Duration delay, Fun fun)
    {
        handlers_ ~= Handler(
            Handler.Type.During,
            fun,
            0,
            delay.total!"msecs",
            1
        );

        return handlers_.length;
    }

    void update(in uint deltaMs)
    {
        import std.algorithm.mutation : remove;

        for (size_t i = 0; i < handlers_.length; ++i) {
            auto handler = &handlers_[i];

            handler.currentMs += deltaMs;

            if (handler.type == Handler.Type.During) {
                handler.fun();
            }

            if (handler.currentMs >= handler.limitMs) {
                if (handler.type != Handler.Type.During) {
                    handler.fun();
                }

                if (handler.type == Handler.Type.Every) {
                    handler.currentMs = 0;
                }

                if (!handler.infinite && --handler.count == 0) {
                    handlers_ = handlers_.remove(i);
                }
            }
        }
    }
}

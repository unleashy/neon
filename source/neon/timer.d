module neon.timer;

import core.time : Duration;

final class Timer
{
    alias Fun = void delegate();

    private struct Handler
    {
        Fun during;
        Fun after;

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
        in (fun !is null)
    {
        return during(delay, &noOp, fun);
    }

    size_t every(in Duration delay, Fun fun, in uint count = 0)
        in (fun !is null)
    {
        handlers_ ~= Handler(
            &noOp,
            fun,
            0,
            delay.total!"msecs",
            count
        );

        return handlers_.length - 1;
    }

    size_t during(in Duration delay, Fun fun, Fun after = null)
        in (fun !is null)
    {
        handlers_ ~= Handler(
            fun,
            after !is null ? after : &noOp,
            0,
            delay.total!"msecs",
            1
        );

        return handlers_.length - 1;
    }

    void cancel(in size_t id)
    {
        import std.algorithm.mutation : remove;
        handlers_ = handlers_.remove(id);
    }

    void update(in uint deltaMs)
    {
        for (size_t i = 0; i < handlers_.length; ++i) {
            auto handler = &handlers_[i];

            handler.currentMs += deltaMs;

            handler.during();

            if (handler.currentMs >= handler.limitMs) {
                handler.after();

                if (handler.infinite) {
                    handler.currentMs = 0;
                } else if (--handler.count == 0) {
                    cancel(i);
                }
            }
        }
    }

    private void noOp()
    {}
}

module neon.timer;

import core.time : Duration;

final class Timer
{
    alias Id  = size_t;
    alias Fun = void delegate();

    private struct Handler
    {
        Id id;

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
    private Id nextId_;

    Id after(in Duration delay, Fun fun)
        in (fun !is null)
    {
        return during(delay, &noOp, fun);
    }

    Id every(in Duration delay, Fun fun, in uint count = 0)
        in (fun !is null)
    {
        handlers_ ~= Handler(
            nextId_,
            &noOp,
            fun,
            0,
            delay.total!"msecs",
            count
        );

        return nextId_++;
    }

    Id during(in Duration delay, Fun fun, Fun after = null)
        in (fun !is null)
    {
        handlers_ ~= Handler(
            nextId_,
            fun,
            after !is null ? after : &noOp,
            0,
            delay.total!"msecs",
            1
        );

        return nextId_++;
    }

    void cancel(in Id id)
    {
        import std.algorithm : countUntil, remove;

        handlers_ = handlers_.remove(handlers_.countUntil!"a.id == b"(id));
    }

    void update(in uint deltaMs)
    {
        import std.algorithm.mutation : SwapStrategy, remove;

        for (size_t i = 0; i < handlers_.length; ++i) {
            auto handler = &handlers_[i];

            handler.currentMs += deltaMs;

            handler.during();

            if (handler.currentMs >= handler.limitMs) {
                handler.after();

                if (handler.infinite) {
                    handler.currentMs = 0;
                } else if (--handler.count == 0) {
                    handlers_ = handlers_.remove!(SwapStrategy.stable)(i);
                }
            }
        }
    }

    private void noOp()
    {}
}

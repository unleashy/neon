module neon.timer;

import core.time : Duration;
import std.uuid  : UUID;

final class Timer
{
    alias Id  = UUID;
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

    private Handler[Id] handlers_;

    Id after(in Duration delay, Fun fun)
        in (fun !is null)
    {
        return during(delay, &noOp, fun);
    }

    Id every(in Duration delay, Fun fun, in uint count = 0)
        in (fun !is null)
    {
        auto id = makeId();

        handlers_[id] = Handler(
            &noOp,
            fun,
            0,
            delay.total!"msecs",
            count
        );

        return id;
    }

    Id during(in Duration delay, Fun fun, Fun after = null)
        in (fun !is null)
    {
        auto id = makeId();

        handlers_[id] = Handler(
            fun,
            after !is null ? after : &noOp,
            0,
            delay.total!"msecs",
            1
        );

        return id;
    }

    void cancel(in Id id)
    {
        handlers_.remove(id);
    }

    void update(in uint deltaMs)
    {
        foreach (id, ref handler; handlers_) {
            handler.currentMs += deltaMs;

            handler.during();

            if (handler.currentMs >= handler.limitMs) {
                handler.after();

                if (handler.infinite) {
                    handler.currentMs = 0;
                } else if (--handler.count == 0) {
                    cancel(id);
                }
            }
        }
    }

    private Id makeId()
    {
        import std.uuid : randomUUID;

        return randomUUID();
    }

    private void noOp()
    {}
}

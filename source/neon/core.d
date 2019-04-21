module neon.core;

import bindbc.sdl;
import bindbc.sdl.image;

import neon.event;
import neon.graphics;
import neon.input;
import neon.timer;
import neon.util;

version (NeonNoAutoInit)
{}
else
{
    shared static this()
    {
        neonInit();
    }

    shared static ~this()
    {
        neonDeinit();
    }
}

private __gshared bool hasInit_;

/**
 * Initialise Neon. Must be called once, at the start of the program, in the
 * main thread.
 *
 * Throws: a NeonException if failed
 */
void neonInit(in uint sdlFlags = SDL_INIT_EVERYTHING)
    in (!hasInit_)
{
    immutable actualSupport = loadSDL();
    if (actualSupport != sdlSupport) {
        immutable msg = {
            if (actualSupport == SDLSupport.noLibrary) {
                return "This application requires the SDL library.";
            } else {
                return "The version of the SDL library on your system is " ~
                       "too low. Please upgrade.";
            }
        }();

        throw new NeonException(msg);
    }

    immutable actualImgSupport = loadSDLImage();
    if (actualImgSupport != sdlImageSupport) {
        immutable msg = {
            if (actualImgSupport == SDLImageSupport.noLibrary) {
                return "This application requires the SDL_Image library.";
            } else {
                return "The version of the SDL_Image library on your system is " ~
                       "too low. Please upgrade.";
            }
        }();

        throw new NeonException(msg);
    }

    enforceSDL(SDL_Init(sdlFlags) == 0);
    enforceSDL(IMG_Init(IMG_INIT_PNG) == IMG_INIT_PNG);

    hasInit_ = true;
}

/**
 * Deinitialises Neon. Must be called once, at the end of the program, in the
 * main thread.
 */
void neonDeinit()
    in (hasInit_)
{
    IMG_Quit();
    SDL_Quit();

    unloadSDLImage();
    unloadSDL();
}

struct Neon
{
@safe static:
    private Graphics graphics_;
    private Input input_;
    private Timer timer_;

    Graphics graphics() @nogc nothrow
        out (r; r !is null)
    {
        return graphics_;
    }

    void graphics(Graphics graphics) @nogc nothrow
        in (graphics !is null)
    {
        graphics_ = graphics;
    }

    Input input() @nogc nothrow
        out (r; r !is null)
    {
        return input_;
    }

    void input(Input input) @nogc nothrow
        in (input !is null)
    {
        input_ = input;
    }

    Timer timer() @nogc nothrow
        out (r; r !is null)
    {
        return timer_;
    }

    void timer(Timer timer) @nogc nothrow
        in (timer !is null)
    {
        timer_ = timer;
    }
}

void neonRun(Game)(auto ref Game game)
{
    import std.range  : isInputRange;
    import std.traits : ReturnType;

    enum hasLoad   = is(typeof((Game g) => g.load()));
    enum hasUpdate = is(typeof((Game g) => g.update()));
    enum hasDraw   = is(typeof((Game g) => g.draw(float.init)));

    // TODO: let the user configure this
    enum msPerUpdate = 10;

    void fireEvents(T)(SDL_Event e) {
        import std.traits : isFunction, getSymbolsByUDA, getUDAs;

        const ev = T.fromSDLEvent(e);
        static foreach (handler; getSymbolsByUDA!(Game, On!T)) {
            static if (isFunction!handler) {
                mixin("game." ~ __traits(identifier, handler) ~ "(ev);");
            }
        }
    }

    Neon.graphics = new Graphics();
    scope(exit) Neon.graphics.deinit();

    Neon.input = new Input();
    Neon.timer = new Timer();

    static if (hasLoad) {
        game.load();
    }

    bool running = true;
    uint previousTime = SDL_GetTicks();
    float lag = 0.0;

    Neon.graphics.showWindow();

    while (running) {
        immutable currentTime = SDL_GetTicks();
        immutable elapsedTime = currentTime - previousTime;
        previousTime = currentTime;
        lag += elapsedTime;

        // TODO: handle events properly
        SDL_Event e;

        while (SDL_PollEvent(&e)) {
            switch (e.type) {
                case SDL_QUIT:
                    running = false;
                    break;

                case SDL_KEYDOWN:
                    Neon.input.keyDown(e.key.keysym.scancode);
                    fireEvents!KeyPressedEvent(e);
                    break;

                case SDL_KEYUP:
                    Neon.input.keyUp(e.key.keysym.scancode);
                    fireEvents!KeyReleasedEvent(e);
                    break;

                default: break;
            }
        }

        static if (hasUpdate) {
            uint maxIters = 5;
            while (lag >= msPerUpdate && --maxIters > 0) {
                static if (is(ReturnType!(game.update) == bool)) {
                    running = game.update();
                } else {
                    game.update();
                }

                Neon.timer.update(msPerUpdate);

                lag -= msPerUpdate;
            }
        }

        static if (hasDraw) {
            Neon.graphics.clear();

            game.draw(lag / msPerUpdate);

            Neon.graphics.present();
        }

        SDL_Delay(1); // bound it to 1000 fps and greatly reduce CPU usage
    }
}

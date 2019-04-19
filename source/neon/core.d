module neon.core;

import bindbc.sdl;

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

    enforceSDL(SDL_Init(sdlFlags) == 0);

    hasInit_ = true;
}

/**
 * Deinitialises Neon. Must be called once, at the end of the program, in the
 * main thread.
 */
void neonDeinit()
    in (hasInit_)
{
    SDL_Quit();

    unloadSDL();
}

void neonRun(Game)(auto ref Game game)
{
    import neon.graphics : Graphics;

    enum hasLoad   = is(typeof((Game g) => g.load(Graphics.init)));
    enum hasUpdate = is(typeof((Game g) => g.update()));
    enum hasDraw   = is(typeof((Game g) => g.draw(Graphics.init, float.init)));

    // TODO: let the user configure this
    enum msPerUpdate = 10;

    auto graphics = new Graphics();

    static if (hasLoad) {
        game.load(graphics);
    }

    bool running = true;
    uint previousTime = SDL_GetTicks();
    float lag = 0.0;

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

                default: break;
            }
        }

        static if (hasUpdate) {
            uint maxIters = 5;
            while (lag >= msPerUpdate && --maxIters > 0) {
                game.update();
                lag -= msPerUpdate;
            }
        }

        static if (hasDraw) {
            game.draw(graphics, lag / msPerUpdate);
        }

        SDL_Delay(1); // bound it to 1000 fps and greatly reduce CPU usage
    }
}

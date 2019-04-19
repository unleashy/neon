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

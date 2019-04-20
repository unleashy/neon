module neon.input;

import bindbc.sdl;

@safe:

final class Input
{
    private bool[SDL_NUM_SCANCODES] keyDown_;

    void keyDown(in SDL_Scancode sc) @nogc nothrow pure
    {
        keyDown_[sc] = true;
    }

    void keyUp(in SDL_Scancode sc) @nogc nothrow pure
    {
        keyDown_[sc] = false;
    }

    bool isKeyDown(in SDL_Scancode sc) @nogc const nothrow pure
    {
        return keyDown_[sc];
    }
}

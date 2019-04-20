module neon.event;

import bindbc.sdl;

alias On(alias Event) = Event;

struct KeyPressedEvent
{
    SDL_Scancode key;
    ushort modifiers;
    bool isRepeating;

    package static KeyPressedEvent fromSDLEvent(SDL_Event e)
        in (e.type == SDL_KEYDOWN)
    {
        return KeyPressedEvent(
            e.key.keysym.scancode,
            e.key.keysym.mod,
            e.key.repeat > 0
        );
    }
}

struct KeyReleasedEvent
{
    SDL_Scancode key;
    ushort modifiers;

    package static KeyReleasedEvent fromSDLEvent(SDL_Event e)
        in (e.type == SDL_KEYUP)
    {
        return KeyReleasedEvent(
            e.key.keysym.scancode,
            e.key.keysym.mod
        );
    }
}

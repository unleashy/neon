module neon.event;

import bindbc.sdl;

alias On(alias Event) = Event;

struct KeyPressedEvent
{
    SDL_Scancode key;

    package static KeyPressedEvent fromSDLEvent(SDL_Event e)
        in (e.type == SDL_KEYDOWN)
    {
        return KeyPressedEvent(e.key.keysym.scancode);
    }
}

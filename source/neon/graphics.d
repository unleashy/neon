module neon.graphics;

import bindbc.sdl;
import bindbc.sdl.image;

import neon.util;

struct Dimension
{
    uint width;
    uint height;
}

struct Coord
{
    int x;
    int y;
}

struct Rect
{
    int x;
    int y;
    int w;
    int h;
}

struct Colour
{
    ubyte r;
    ubyte g;
    ubyte b;
    ubyte a = 255;

    this(in ubyte r, in ubyte g, in ubyte b, in ubyte a = Colour.init.a)
    {
        this.r = r;
        this.g = g;
        this.b = b;
        this.a = a;
    }

    this(in uint hex)
    {
        this(
            cast(ubyte) (hex >> 24),
            cast(ubyte) ((hex >> 16) & 0xFF),
            cast(ubyte) ((hex >> 8) & 0xFF),
            cast(ubyte) (hex & 0xFF)
        );
    }
}

struct Image
{
    private SDL_Texture* tex_;
    private Dimension dim_;

    uint width() @safe @property @nogc const nothrow pure
    {
        return dim_.width;
    }

    uint height() @safe @property @nogc const nothrow pure
    {
        return dim_.height;
    }
}

final class Graphics
{
    private immutable(char)* name_;
    private SDL_Window* window_;
    private SDL_Renderer* renderer_;

    private Colour drawColour_;
    private Colour clearColour_;

    this()
    {
        import std.string : toStringz;

        name_ = toStringz("neon");

        window_ = SDL_CreateWindow(
            name_,
            SDL_WINDOWPOS_CENTERED,
            SDL_WINDOWPOS_CENTERED,
            640,
            480,
            SDL_WINDOW_HIDDEN
        );

        enforceSDL(window_ !is null);

        renderer_ = SDL_CreateRenderer(window_, -1, cast(SDL_RendererFlags) 0);

        enforceSDL(renderer_ !is null);
    }

    package void deinit() @nogc nothrow
    {
        SDL_DestroyRenderer(renderer_);
        SDL_DestroyWindow(window_);
    }

    void clear()
    {
        SDL_SetRenderDrawColor(renderer_, clearColour_.r, clearColour_.g, clearColour_.b, clearColour_.a);
        enforceSDL(SDL_RenderClear(renderer_) == 0);
    }

    void present() @nogc nothrow
    {
        SDL_RenderPresent(renderer_);
    }

    Image loadImage(in string path)
    {
        import std.exception : enforce;
        import std.file      : exists;
        import std.string    : toStringz;

        enforce!NeonException(exists(path), "given image path '" ~ path ~ "' does not exist");

        SDL_Surface* surf = IMG_Load(toStringz(path));
        enforceSDL(surf !is null);
        scope(exit) SDL_FreeSurface(surf);

        SDL_Texture* tex = SDL_CreateTextureFromSurface(renderer_, surf);
        enforceSDL(tex !is null);

        return Image(tex, Dimension(surf.w, surf.h));
    }

    auto withColour(in Colour colour)
    {
        static struct BoundColourGraphics
        {
            Graphics graphics;
            Colour colour;

            auto opDispatch(string funName, Args...)(Args args)
            {
                enum fun = "graphics." ~ funName ~ "(args)";
                enum isVoid = is(typeof(mixin(fun)) == void);

                immutable prevColour = graphics.drawColour;

                graphics.drawColour = colour;

                static if (isVoid) {
                    mixin(fun ~ ";");
                } else {
                    auto result = mixin(fun);
                }

                graphics.drawColour = prevColour;

                static if (!isVoid) {
                    return result;
                }
            }
        }

        return BoundColourGraphics(this, colour);
    }

    void draw(Image image, in Coord at)
    {
        SDL_Rect rect = SDL_Rect(at.x, at.y, image.width, image.height);
        SDL_RenderCopy(renderer_, image.tex_, null, &rect);
    }

    void fillRect(in Rect rect)
    {
        SDL_Rect sdlR = cast(SDL_Rect) rect;
        SDL_RenderFillRect(renderer_, &sdlR);
    }

    void showWindow() @nogc nothrow
    {
        SDL_ShowWindow(window_);
    }

    void hideWindow() @nogc nothrow
    {
        SDL_HideWindow(window_);
    }

    Colour drawColour() @property @nogc const nothrow
    {
        return drawColour_;
    }

    void drawColour(in Colour colour) @property @nogc nothrow
    {
        SDL_SetRenderDrawColor(renderer_, colour.r, colour.g, colour.b, colour.a);
        drawColour_ = colour;
    }

    Colour clearColour() @property @nogc const nothrow
    {
        return clearColour_;
    }

    void clearColour(in Colour colour) @property @nogc nothrow
    {
        clearColour_ = colour;
    }

    const(char)[] windowTitle() @property @nogc const nothrow
    {
        import std.string : fromStringz;

        return fromStringz(SDL_GetWindowTitle(cast(SDL_Window*) window_));
    }

    void windowTitle(in string title) @property nothrow
    {
        import std.string : toStringz;

        name_ = toStringz(title);
        SDL_SetWindowTitle(window_, name_);
    }

    Dimension windowSize() @property @nogc const nothrow
    {
        int width, height;
        SDL_GetWindowSize(cast(SDL_Window*) window_, &width, &height);
        return Dimension(cast(uint) width, cast(uint) height);
    }

    void windowSize(in Dimension dim) @property @nogc nothrow
    {
        SDL_SetWindowSize(window_, cast(int) dim.width, cast(int) dim.height);
    }
}

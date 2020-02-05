## MoonNuklear: Lua bindings for Nuklear

MoonNuklear is a Lua binding library for Mitcha Mettke's [Nuklear](https://github.com/Immediate-Mode-UI/nuklear) immediate mode GUI toolkit.

It runs on GNU/Linux, on MacOS, and on Windows (MSYS2/MinGW) and requires [Lua](http://www.lua.org/) (>=5.3).


_Author:_ _[Stefano Trettel](https://www.linkedin.com/in/stetre)_

[![Lua logo](./doc/powered-by-lua.gif)](http://www.lua.org/)

#### License

MIT/X11 license (same as Lua). See [LICENSE](./LICENSE).

#### Documentation

See the [Reference Manual](https://stetre.github.io/moonnuklear/doc/index.html).

#### Getting and installing

Setup the build environment as described [here](https://github.com/stetre/moonlibs), then:

```sh
$ git clone https://github.com/stetre/moonnuklear
$ cd moonnuklear
moonnuklear$ make
moonnuklear$ make install # or 'sudo make install' (Ubuntu and MacOS)
```

#### Example

The example below shows the front-end implementation of a simple GUI.

The backend and other examples can be found in the **examples/** directory contained in the release package.

```lua
local nk = require("moonnuklear")
local backend = require("backend")

local op = 'easy'
local value = 0.6
local window_flags = nk.WINDOW_BORDER|nk.WINDOW_MOVABLE|nk.WINDOW_CLOSABLE

local function hellogui(ctx)
   if nk.window_begin(ctx, "Show", {50, 50, 220, 220}, window_flags) then
      -- fixed widget pixel width
      nk.layout_row_static(ctx, 30, 80, 1)

      if nk.button(ctx, nil, "button") then
         -- ... event handling ...
         print("button pressed")
      end

      -- fixed widget window ratio width
      nk.layout_row_dynamic(ctx, 30, 2)
      if nk.option(ctx, 'easy', op == 'easy') then op = 'easy' end
      if nk.option(ctx, 'hard', op == 'hard') then op = 'hard' end

      -- custom widget pixel width
      nk.layout_row_begin(ctx, 'static', 30, 2)
      nk.layout_row_push(ctx, 50)
      nk.label(ctx, "Volume:", nk.TEXT_LEFT)
      nk.layout_row_push(ctx, 110)
      value = nk.slider(ctx, 0, value, 1.0, 0.1)
      nk.layout_row_end(ctx)
   end
   nk.window_end(ctx)
end

-- Init the backend and enter the event loop:
backend.init(640, 380, "Hello", true, nil)
backend.loop(hellogui, {.13, .29, .53, 1}, 30)

```
The script can be executed at the shell prompt with the standard Lua interpreter:

```shell
$ lua hello.lua
```

#### See also

* [MoonLibs - Graphics and Audio Lua Libraries](https://github.com/stetre/moonlibs).


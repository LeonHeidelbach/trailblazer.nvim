# TrailBlazer.nvim ⛺🌳

[![Integration][integration-badge]][integration-runs]

TrailBlazer enables you to seemlessly move through important project marks as quickly and
efficiently as possible to make your workflow *blazingly fast ™*.

<figure>
    <blockquote cite="https://www.huxley.net/bnw/four.html">
        <p>
            TrailBlazer is the plugin we didn't deserve but most definitely need. It has
            fundamentally transformed the way I use my text editor on a daily basis. Truely a
            beautifully simple plugin of the people, by the people, for Neovim users.
        </p>
        <figcaption style="font-size:11pt;text-align:right;">
            — Abraham Lincoln, <cite>November 19th 1863</cite>
        </figcaption>
    </blockquote>
</figure>

Do not blindly believe any quote on the internet, even though the one above is most certainly
accurate.

Navigating back and forth between multiple very specific points of interest in one or more files
spread over several windows can be a rather difficult task. Most of the time those spots are either
located too far apart within one file to do a quick relative jump or to use [leap.nvim][leap.nvim]
or are spread out between multiple documents but also not located at the same spot when using
[harpoon][harpoon] jumps. Remembering default Neovim mark names on a per buffer basis is annoying
and takes up valuable [RAM][ram-def-wikipedia] in your brain. Thus moving between those locations
within large projects can slow you down tremendously. TrailBlazer aims to solve this problem by
enabling you to leave trail marks as you navigate multiple files over different windows and buffers.
Quickly move along the trail you mark as you journey through your project and start working right
away wherever you need to come back to a previous trail mark. You can even use several immediate
actions on your trail marks that allow you to be even more efficient.

**NOTE: TrailBlazer is still in its early stages of development and there are still many features 
to come. If you have any suggestions or find any bugs, please open an issue.**

## 🔨 Requirements

* Neovim (**stable** or **nightly**) >= 0.8.0

TrailBlazer will usually support the current stable and nightly versions of Neovim. Older versions
will most likely still work, but are no longer tested.

## 📦 Installation

You can install TrailBlazer through your favorite plugin manager:

```lua
-- Using packer
use({
    "LeonHeidelbach/trailblazer.nvim",
    config = function()
        require("trailblazer").setup({
            -- your custom config goes here
        })
    end,
})
```

## ⚙️ Configuration

You can configure TrailBlazer by passing a table to the `setup` function. The following options are
available and set by default:

```lua
-- Adjust these values to your liking
{
    lang = "en",
    mappings = {
        nv = { -- Mode union: normal & visual mode. Can be extended by adding i, x, ...
            motions = {
                new_trail_mark = '<A-l>',
                track_back = '<A-b>',
                peek_move_backward = '<A-J>',
                peek_move_forward = '<A-K>',
            },
            actions = {
                delete_all_trail_marks = '<A-L>',
                paste_at_last_trail_mark = '<A-p>',
                paste_at_all_trail_marks = '<A-P>',
            },
        },
        -- You can also add/move any motion or action to mode specific mappings i.e.:
        -- i = {
        --     motions = {
        --         new_trail_mark = '<C-l>',
        --         ...
        --     },
        --     ...
        -- },
    },
    hl_groups = {
        TrailBlazerTrailMark = { 
        -- You can add any valid highlight group attribute to this table
            guifg = "Black",
            guibg = "Red",
            gui = "bold",
        },
    },
}
```

## User commands

Arguments annotated with `?` can be omitted. If omitted, the current window, buffer, cursor position
and the global trail mark stack will be used. All user commands use functions defined
within the main TrailBlazer API module [lua/trailblazer/init.lua][user_api] which can also be used
directly like this:

```lua
require("trailblazer").<function_name>(<args>)
```

| Command                            | Arguments                                                                                                      | Function                      | Description                                                                                                                                                        |
|------------------------------------|----------------------------------------------------------------------------------------------------------------|-------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `:TrailBlazerNewTrailMark`         | `<window? number>`<br>`<buffer? string \| number>`<br>`<cursor_pos_row? number>`<br>`<cursor_pos_col? number>` | new_trail_mark(win, buf, pos) | Create a new trail mark at the current cursor position or at the specified window / buffer / position.                                                             |
| `:TrailBlazerTrackBack`            | `<buffer? string \| number>`                                                                                   | track_back(buf)               | Move to the last global trail mark or the last one within the specified buffer and remove it from the trail mark stack.                                            |
| `:TrailBlazerPeekMoveForward`      | `<buffer? string \| number`                                                                                    | peek_move_forward(buf)        | Move to the next global trail mark or the next one within the specified buffer leading up to the newest one without removing it from the trail mark stack.         |
| `:TrailBlazerPeekMoveBackward`     | `<buffer? string \| number>`                                                                                   | peek_move_backward(buf)       | Move to the previous global trail mark or the previous one within the specified buffer leading up to the oldest one without removing it from the trail mark stack. |
| `:TrailBlazerDeleteAllTrailMarks`  | `<buffer? string \| number>`                                                                                   | delete_all_trail_marks(buf)   | Delete all trail marks globally or within the specified buffer.                                                                                                    |
| `:TrailBlazerPasteAtLastTrailMark` | `<buffer? string \| number>`                                                                                   | paste_at_last_trail_mark(buf) | Paste the contents of any selected register at the last global trail mark or the last one within the specified buffer and remove it from the trail mark stack.     |
| `:TrailBlazerPasteAtAllTrailMarks` | `<buffer? string \| number>`                                                                                   | paste_at_all_trail_marks(buf) | Paste the contents of any selected register at all global trail marks or at all trail marks within the specified buffer.                                           |

## Documentation

You can find the technical documentation for TrailBlazer under [doc/trailblazer.nvim.txt][help]. If
you are within Neovim you can also open the documentation by running `:help trailblazer.nvim`.

## Contributing

I would like to keep TrailBlazer's code base as clean and easy to read as possible. If you would
like to contribute, please make sure to follow the following contribution guidelines and make sure
to add method documentations to your code:

#### Linting

TrailBlazer uses [LuaCheck][luacheck] to lint the code base. You will have to install [Lua][lua] as
well as [LuaRocks][luarocks] to run and install [LuaCheck][luacheck]. To get started, simply follow
these steps:

Install [LuaCheck][luacheck] through [LuaRocks][luarocks]:

```console
$ luarocks install luacheck
```

After adding the [LuaRocks][luarocks] binary directory to your `$PATH` you can use this command to
lint the code:

```console
$ luacheck lua/ test/spec/
```

#### Testing

TrailBlazer uses [busted][busted], [luassert][luassert] (through [plenary.nvim][plenary]) and
[matcher_combinators][matcher_combinators] to define tests in the `./test/spec` directory. If you
are planning to contribute, make sure all tests pass prior to creating a pull request.

Make sure your shell is in the `./test` directory or, if it is in the root directory,
replace `make` by `make -C ./test` in the commands below.

To initialize all test dependencies and execute the test suite simply run:

```console
$ make prepare
$ make test
```

## Feedback

Feedback is always welcome! If you would like to leave some, please use the [GitHub
Discussions][discussions]. Issues are reserved for bug reports and feature requests.

[user_api]: lua/trailblazer/init.lua
[ram-def-wikipedia]: https://en.wikipedia.org/wiki/Random-access_memory
[lua]: https://www.lua.org/
[luarocks]: https://luarocks.org/
[luacheck]: https://github.com/mpeterv/luacheck
[leap.nvim]: https://github.com/ggandor/leap.nvim
[harpoon]: https://github.com/ThePrimeagen/harpoon
[busted]: https://olivinelabs.com/busted/
[luassert]: https://github.com/Olivine-Labs/luassert
[plenary]: https://github.com/nvim-lua/plenary.nvim
[matcher_combinators]: https://github.com/m00qek/matcher_combinators.lua
[integration-badge]: https://github.com/LeonHeidelbach/trailblazer.nvim/actions/workflows/integration.yml/badge.svg
[integration-runs]: https://github.com/LeonHeidelbach/trailblazer.nvim/actions/workflows/integration.yml
[neovim-test-versions]: .github/workflows/integration.yml#L17
[help]: doc/trailblazer.nvim.txt
[discussions]: https://github.com/LeonHeidelbach/trailblazer.nvim/discussions
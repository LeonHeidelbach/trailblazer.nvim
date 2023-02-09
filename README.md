<h1 dir="auto" align="center">TrailBlazer.nvim ⛺🌳</h1>

<p align="center" dir="auto">
    <a href="https://www.gnu.org/licenses/gpl-3.0.en.html" rel="nofollow"><img alt="GPLv3" src="https://img.shields.io/badge/License-GPLv3-blue.svg?style=for-the-badge" style="max-width: 100%;"></a>
    <a href="https://en.wikipedia.org/wiki/Free_and_open-source_software" rel="nofollow"><img alt="FOSS" src="https://img.shields.io/badge/FOSS-%E2%9C%93-blue.svg?style=for-the-badge" style="max-width: 100%;"></a>
    <a href="https://www.lua.org/" rel="nofollow"><img alt="Lua" src="https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&amp;logo=lua" style="max-width: 100%;"></a>
    <a href="https://neovim.io/" rel="nofollow"><img alt="Neovim" src="https://img.shields.io/badge/Neovim%200.8+-green.svg?style=for-the-badge&amp;logo=neovim" style="max-width: 100%;"></a></p>
</p>

<p align="center" dir="auto">
    <a href="https://github.com/LeonHeidelbach/trailblazer.nvim/actions/workflows/integration.yml"><img src="https://github.com/LeonHeidelbach/trailblazer.nvim/actions/workflows/integration.yml/badge.svg" alt="Integration" style="max-width: 100%;"></a>
</p>

TrailBlazer enables you to seemlessly move through important project marks as quickly and
efficiently as possible to make your workflow *blazingly fast ™*.

<figure>
    <blockquote>
        <p>
            TrailBlazer is the plugin we didn't deserve but most definitely need. It has
            fundamentally transformed the way I use my text editor on a daily basis. Truely a
            beautifully simple plugin of the people, by the people, for Neovim users.
        </p>
        <p style="font-size:11pt;text-align:right;">
            — Abraham Lincoln, <cite>November 19th 1863</cite>
        </p>
        </blockquote>
</figure>

Do not blindly believe any quote on the internet, even though the one above is most certainly
accurate.

![showcase][showcase]

**NOTE: TrailBlazer is still in its early stages of development and there are still many features
to come. If you have any suggestions or find any bugs, please open an issue.**

## Contents

* [TrailBlazer](#trailblazernvim-)
    * [❓ Why Does TrailBlazer Exist?](#-why-does-trailblazer-exist)
    * [🔥 How To Properly Blaze The Trail](#-how-to-properly-blaze-the-trail)
    * [🔨 Requirements](#-requirements)
    * [📦 Installation](#-installation)
    * [⚙️ Configuration](#%EF%B8%8F-configuration)
        * [Trail Mark Stacks](#trail-mark-stacks)
        * [Trail Mark Sessions](#trail-mark-sessions)
        * [Trail Mark Selection Modes](#trail-mark-selection-modes)
        * [Trail Mark Symbols](#trail-mark-symbols)
            * [Multiple Mark Symbol Counters](#multiple-mark-symbol-counters)
        * [Trail Mark QuickFix-List](#trail-mark-quickfix-list)
    * [💻 User commands](#-user-commands)
    * [📚 Documentation](#-documentation)
    * [👥 Contributing](#-contributing)
        * [Linting](#linting)
        * [Testing](#testing)
    * [💬 Feedback](#-feedback)

## ❓ Why Does TrailBlazer Exist?

Navigating back and forth between multiple very specific points of interest in one or more files
spread over several windows can be a rather difficult task. Most of the time those spots are either
located too far apart within one file to do a quick relative jump or to use [leap.nvim][leap.nvim]
or are spread out between multiple documents but also not located at the same spot when using
[harpoon][harpoon] jumps. Remembering default [Neovim][neovim] mark names on a per buffer basis is
annoying and takes up valuable [RAM][ram-def-wikipedia] in your brain. Thus moving between those
locations within large projects can slow you down tremendously. TrailBlazer aims to solve this
problem by enabling you to leave trail marks as you navigate multiple files over different windows
and buffers. Quickly move along the trail you mark as you journey through your project and start
working wherever you left off right away whenever you need to. You can even use several immediate
actions on your trail marks that allow you to be even more efficient. You can also toggle a reactive
list view of all your trail marks and quickly jump to any of them.

## 🔥 How To Properly Blaze The Trail

You could just use TrailBlazer trail marks as you would normal Neovim marks, but with a few
optimalizations to make your workflow more efficient. The real power of this plugin however, lies
within its ability to quickly create and consume trail marks from the stack as you edit your code.
This enables you to quickly "bookmark" where you are right now, naviagte to wherever you need to and
come back by simply popping the last mark off the stack using the "track back" feature. This is
especially useful when you need to quickly jump to a specific location in a different file or window
and return afterwards without the need for a permanent mark. The length of these short lived trails
is completely up to you and you can even go back to an ealier mark, do whatever you need to do and
track back to your "bookmarked" location from there. The "track back" feature always brings you back
to the last mark you left and consumes it from the stack. As a common use case for a feature like
this is to quickly copy and paste something from one spot to another, TrailBlazer gives you several
builtin stack actions like "paste at the newest trail mark" to quickly paste whatever contents you
yanked into any Neovim register at the last trail mark and consume it. You can also do the same
thing for all trail marks by using the "paste at all trail marks" action. As TrailBlazer continues
to be developed, more actions will be added to enable you to be even more efficient.

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
    auto_save_trailblazer_state_on_exit = false,
    auto_load_trailblazer_state_on_enter = false, -- experimental
    custom_session_storage_dir = "", -- i.e. "~/trail_blazer_sessions/"
    trail_options = {
        -- Available modes to cycle through. Remove any you don't need.
        available_trail_mark_modes = {
            "global_chron",
            "global_buf_line_sorted",
            "global_chron_buf_line_sorted",
            "global_chron_buf_switch_group_chron",
            "global_chron_buf_switch_group_line_sorted",
            "buffer_local_chron",
            "buffer_local_line_sorted"
        },
        -- The current / initially selected trail mark selection mode. Choose from one of the
        -- available modes: global_chron, global_buf_line_sorted, global_chron_buf_line_sorted,
        -- global_chron_buf_switch_group_chron, global_chron_buf_switch_group_line_sorted,
        -- buffer_local_chron, buffer_local_line_sorted
        current_trail_mark_mode = "global_chron",
        current_trail_mark_list_type = "quickfix", -- currently only quickfix lists are supported
        verbose_trail_mark_select = true, -- print current mode notification on mode change
        mark_symbol = "•", --  will only be used if trail_mark_symbol_line_indicators_enabled = true
        newest_mark_symbol = "⬤", -- disable this mark symbol by setting its value to ""
        cursor_mark_symbol = "⬤", -- disable this mark symbol by setting its value to ""
        next_mark_symbol = "⬤", -- disable this mark symbol by setting its value to ""
        previous_mark_symbol = "⬤", -- disable this mark symbol by setting its value to ""
        multiple_mark_symbol_counters_enabled = true,
        number_line_color_enabled = true,
        trail_mark_in_text_highlights_enabled = true,
        trail_mark_symbol_line_indicators_enabled = false, -- show indicators for all trail marks in symbol column
        symbol_line_enabled = true,
        default_trail_mark_stacks = {
            -- this is the list of trail mark stacks that will be created by default. Add as many
            -- as you like to this list. You can always create new ones in Neovim by using either
            -- `:TrailBlazerSwitchTrailMarkStack <name>` or `:TrailBlazerAddTrailMarkStack <name>`
            "default" -- , "stack_2", ...
        },
        available_trail_mark_stack_sort_modes = {
            "alpha_asc", -- alphabetical ascending
            "alpha_dsc", -- alphabetical descending
            "chron_asc", -- chronological ascending
            "chron_dsc", -- chronological descending
        },
        -- The current / initially selected trail mark stack sort mode. Choose from one of the
        -- available modes: alpha_asc, alpha_dsc, chron_asc, chron_dsc
        current_trail_mark_stack_sort_mode = "alpha_asc"
    },
    mappings = { -- rename this to "force_mappings" to completely override default mappings and not merge with them
        nv = { -- Mode union: normal & visual mode. Can be extended by adding i, x, ...
            motions = {
                new_trail_mark = '<A-l>',
                track_back = '<A-b>',
                peek_move_next_down = '<A-J>',
                peek_move_previous_up = '<A-K>',
                toggle_trail_mark_list = '<A-m>',
            },
            actions = {
                delete_all_trail_marks = '<A-L>',
                paste_at_last_trail_mark = '<A-p>',
                paste_at_all_trail_marks = '<A-P>',
                set_trail_mark_select_mode = '<A-t>',
                switch_to_next_trail_mark_stack = '<A-.>',
                switch_to_previous_trail_mark_stack = '<A-,>',
                set_trail_mark_stack_sort_mode = '<A-s>',
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
            guifg = "White",
            guibg = "none",
            gui = "bold",
        },
        TrailBlazerTrailMarkNext = {
            guifg = "Green",
            guibg = "none",
            gui = "bold",
        },
        TrailBlazerTrailMarkPrevious = {
            guifg = "Red",
            guibg = "none",
            gui = "bold",
        },
        TrailBlazerTrailMarkCursor = {
            guifg = "Black",
            guibg = "Orange",
            gui = "bold",
        },
        TrailBlazerTrailMarkNewest = {
            guifg = "Black",
            guibg = "LightBlue",
            gui = "bold",
        },
        TrailBlazerTrailMarkGlobalChron = {
            guifg = "Black",
            guibg = "Red",
            gui = "bold",
        },
        TrailBlazerTrailMarkGlobalBufLineSorted = {
            guifg = "Black",
            guibg = "LightRed",
            gui = "bold",
        },
        TrailBlazerTrailMarkGlobalChronBufLineSorted = {
            guifg = "Black",
            guibg = "Olive",
            gui = "bold",
        },
        TrailBlazerTrailMarkGlobalChronBufSwitchGroupChron = {
            guifg = "Black",
            guibg = "VioletRed",
            gui = "bold",
        },
        TrailBlazerTrailMarkGlobalChronBufSwitchGroupLineSorted = {
            guifg = "Black",
            guibg = "MediumSpringGreen",
            gui = "bold",
        },
        TrailBlazerTrailMarkBufferLocalChron = {
            guifg = "Black",
            guibg = "Green",
            gui = "bold",
        },
        TrailBlazerTrailMarkBufferLocalLineSorted = {
            guifg = "Black",
            guibg = "LightGreen",
            gui = "bold",
        },
    },
}
```

### Trail mark stacks

Trail mark stacks are a collection of trail marks which you can traverse in many different ways by
setting a specific trail mark selection mode. You can find out how those modes work further down
below.

You can create as many trail mark stacks as you like, which allows you to group trail marks in any
way you want, depending on your project needs. You can give your trail mark stacks names and use
different sorting modes when switching between them. By default there is only one trail mark stack,
called `default`, and if that is enough for you, you don't ever have to create any new stacks. New
trail marks will always be added to the currently selected trail mark stack.

| Mode        | Description                                                                                                                     |
|-------------|---------------------------------------------------------------------------------------------------------------------------------|
| `alpha_asc` | This is the default mode. Trail mark stacks are cycled through in alphabetically ascending order depending on their given name. |
| `alpha_dsc` | Trail mark stacks are cycled through in alphabetically descending order depending on their given name.                          |
| `chron_asc` | Trail mark stacks are cycled through in chronological ascending order depending on their creation time.                         |
| `chron_dsc` | Trail mark stacks are cycled through in chronological descending order depending on their creation time.                        |

### Trail Mark Sessions

Trail mark sessions allow you to save and restore your trail mark stacks and current mode
configuration. You can either save a session in TrailBlazer's default session directory which is
located within Neovim's `data` directory or with a given name in any directory you like and restore
it from there. You can find out where Neovim's `data` directory is located on your machine by
calling `:echo stdpath('data')` from the commandline. TrailBlazer session save files are portable,
meaning you can even commit them to your git project and restore your session on a different
computer as long as all files in your session are located relative to your project root or their
absolute file path is valid.

If you run `:TrailBlazerSaveSession` without any arguments, the current session will be saved in the
default session directory and running `:TrailBlazerLoadSession` without any arguments will load this
session from the default session directory. All sessions in the default session directory are
automatically associated with the current working directory. This means that if you change your
working directory and run `:TrailBlazerLoadSession` without any arguments again, the corresponding
session for the new working directory will be loaded. If you pass either a directory or file name to
`:TrailBlazerSaveSession` or `:TrailBlazerLoadSession`, the session will be saved into or loaded
from the given directory or file. Note that you have to append any file extension (e.g. ".tbsv") to
the file name argument when saving a session. Otherwise TrailBlazer will create a directory with the
given name and save the session file named as the hashed path of the current working directory.
Passing a directory name to `:TrailBlazerLoadSession` will cause TrailBlazer to search for a session
file which matches the name of the hashed path of the current working directory.

With trail mark sessions you can enable the following options in your configuration:

* `auto_save_trailblazer_state_on_exit = false`
* `auto_load_trailblazer_state_on_enter = false` (experimental)

If you set `auto_save_trailblazer_state_on_exit` to `true`, TrailBlazer will automatically save the
current session when you exit Neovim, but only if you have previously loaded or saved a session. If
you set `auto_load_trailblazer_state_on_enter` to `true`, TrailBlazer will automatically load the
session which matches the current working directory when you enter Neovim, but only if you have a
session saved for this directory.

### Trail mark selection modes

Trail mark selection modes allow you to switch between different modes of traversing and executing
actions on your trail marks. Add the ones you would like to use to your configuration table. By
default all modes are enabled. Thus far you can choose between the following modes:

| Mode                                        | Description                                                                                                                                                                         |
|---------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `global_chron`                              | This is the default mode. Marks are traversed globally in chronological order.                                                                                                      |
| `global_buf_line_sorted`                    | Marks are sorted by their buffer id and globally traversed from BOF to EOF.                                                                                                         |
| `global_chron_buf_line_sorted`              | Marks are sorted chronologically, then by their buffer id and globally traversed from BOF to EOF.                                                                                   |
| `global_chron_buf_switch_group_chron`       | Marks are sorted chronologically, then by their buffer id and grouped by buffer switch events. Each group switch event is then traversed in chronological order.                    |
| `global_chron_buf_switch_group_line_sorted` | Marks are sorted chronologically, then by their buffer id and grouped by buffer switch events. Each group switch event is then sorted from BOF to EOF within the respective buffer. |
| `buffer_local_chron`                        | Only current buffer marks are traversed chronologically.                                                                                                                            |
| `buffer_local_line_sorted`                  | Only current buffer marks are traversed from BOF to EOF.                                                                                                                            |

### Trail Mark symbols

There are a total of four different mark symbols in TrailBlazer that can be customized to your
liking:

1. The „Newest Mark“ symbol
2. The „Current Cursor“ symbol
3. The „Next Mark“ symbol
4. The „Previous Mark“ symbol

Mark symbols allow you to see at a glance which of your marks is the newest, where the current mark
cursor is located and which mark is the next or previous to be traversed from the current cursor
position within the trail mark stack. As soon as multiple mark symbols would be displayed in the
same line of the sign column, only the last one in the stack, depending on the current sorting of
the stack, will be shown. You can set all mark symbols to any **one** or **two** characters you
like. There can only be a maximum of **two** characters displayed in the sign column at all times,
which is a limitation of the Neovim API. If you set any mark symbol to an empty string (i.e. `""`),
it will be disabled. All mark symbols can be styled through their respective highlight groups.

#### Multiple Mark Symbol Counters

This section is dedicated to the configuration table setting `multiple_mark_symbol_counters_enabled`
which might be a bit confusing at the beginning. As explained in the section above, there are four
types of mark symbols. As soon as there would be multiple mark symbols shown in the same sign column
of a line, with this setting enabled only the last one in the stack will be shown, but now the
number of mark symbols that are currently located within that line will be shown as the leading
character in the sign column. This will give you a better notion of where the different mark symbols
are roughly located even if they are not currently visible in the sign column. With four possible
symbols that can be displayed in the sign column, the highest possible number that will be shown
next to your mark symbol is `4`, if all of the above mark symbols are located on the same line.

##### Let's look at an example of how this works:

As soon as you create a new trail mark it will by default have two of the above symbols, the „Newest
Mark“ symbol and the „Current Cursor“ symbol set to the same line, so you will have the number `2`
visible next to your mark symbol. If you now place a new mark right next to the first one, we
already have three of the possible symbols in the same line as the "Previous Mark" symbol would now
be added to the line changing the displayed number to `3`. If you now add a third mark to the same
line and peek move back to the trail mark before, we have the maximum number of four symbols in the
same line as now the "Next Mark" symbol would also be added to the sign column changing the
displayed number to `4`.

### Trail Mark QuickFix-List

With TrailBlazer you can view, delete and quickly jump to any of your trail marks from within a
QuickFix-List. In the title bar of the QuickFix-List you can see the name of the current trail mark
stack as well as the selection mode. If you are using any "buffer local" selection mode you will
also see the name of the file in the current buffer.

This QuickFix-List does also have a few special features that make editing your trail mark stack
very convenient. The following key maps are currently available within the Trail Mark QuickFix-List:

| Key Maps                     | Key-Code   | Description                                                                       |
|------------------------------|------------|-----------------------------------------------------------------------------------|
| <kbd>Enter</kbd>             | `<CR>`     | Jump to the trail mark under your cursor and set the current trail mark cursor.   |
| <kbd>v</kbd> or <kbd>V</kbd> | `v` or `V` | Enter visual line mode and select multiple trail marks.                           |
| <kbd>d</kbd>                 | `d`        | Delete the trail mark under your cursor or all trail marks within your selection. |

## 💻 User commands

Arguments annotated with `?` can be omitted. If omitted, the current window, buffer, cursor position
and the global trail mark stack will be used. All user commands use functions defined
within the main TrailBlazer API module [lua/trailblazer/init.lua][user_api] which can also be used
directly like this:

```lua
require("trailblazer").<function_name>(<args>)
```

| Command                                    | Arguments                                                                                                      | Description                                                                                                                                                                                                                                            |
|--------------------------------------------|----------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `:TrailBlazerNewTrailMark`                 | `<window? number>`<br>`<buffer? string \| number>`<br>`<cursor_pos_row? number>`<br>`<cursor_pos_col? number>` | Create a new / toggle existing trail mark at the current cursor position or at the specified window / buffer / position.                                                                                                                               |
| `:TrailBlazerTrackBack`                    | `<buffer? string \| number>`                                                                                   | Move to the last global trail mark or the last one within the specified buffer and remove it from the trail mark stack.                                                                                                                                |
| `:TrailBlazerPeekMovePreviousUp`           | `<buffer? string \| number`                                                                                    | Move to the previous global trail mark or the previous one within the specified buffer leading up to the oldest one without removing it from the trail mark stack. In chronologically sorted trail mark modes this will move the trail mark cursor up. |
| `:TrailBlazerPeekMoveNextDown`             | `<buffer? string \| number>`                                                                                   | Move to the next global trail mark or the next one within the specified buffer leading up to the newest one without removing it from the trail mark stack. In chronologically sorted trail mark modes this will move the trail mark cursor down.       |
| `:TrailBlazerDeleteAllTrailMarks`          | `<buffer? string \| number>`                                                                                   | Delete all trail marks globally or within the specified buffer.                                                                                                                                                                                        |
| `:TrailBlazerPasteAtLastTrailMark`         | `<buffer? string \| number>`                                                                                   | Paste the contents of any selected register at the last global trail mark or the last one within the specified buffer and remove it from the trail mark stack.                                                                                         |
| `:TrailBlazerPasteAtAllTrailMarks`         | `<buffer? string \| number>`                                                                                   | Paste the contents of any selected register at all global trail marks or at all trail marks within the specified buffer.                                                                                                                               |
| `:TrailBlazerTrailMarkSelectMode`          | `<mode? string>`                                                                                               | Cycle through or set the current trail mark selection mode.                                                                                                                                                                                            |
| `:TrailBlazerToggleTrailMarkList`          | `<type? string>`<br>`<buffer? string \| number>`                                                               | Toggle a global list of all trail marks or a subset within the given buffer. If no arguments are specified the current trail mark selection mode will be used to populate the list with either a subset or all trail marks in the mode specific order. |
| `:TrailBlazerSwitchTrailMarkStack`         | `<stack_name? string>`                                                                                         | Switch to the specified trail mark stack. If no stack under the specified name exists, it will be created. If no arguments are specified the `default` stack will be selected.                                                                         |
| `:TrailBlazerAddTrailMarkStack`            | `<stack_name? string>`                                                                                         | Add a new trail mark stack. If no arguments are specified the `default` stack will be added to the list of trail mark stacks.                                                                                                                          |
| `:TrailBlazerDeleteTrailMarkStacks`        | `<stack_name? string> ...`                                                                                     | Delete the specified trail mark stacks. If no arguments are specified the current trail mark stack will be deleted.                                                                                                                                    |
| `:TrailBlazerDeleteAllTrailMarkStacks`     | `no arguments`                                                                                                 | Delete all trail mark stacks.                                                                                                                                                                                                                          |
| `:TrailBlazerSwitchNextTrailMarkStack`     | `<sort_mode? string>`                                                                                          | Switch to the next trail mark stack using the specified sorting mode. If no arguments are specified the current default sort mode will be used.                                                                                                        |
| `:TrailBlazerSwitchPreviousTrailMarkStack` | `<sort_mode? string>`                                                                                          | Switch to the previous trail mark stack using the specified sorting mode. If no arguments are specified the current default sort mode will be used.                                                                                                    |
| `:TrailBlazerSetTrailMarkStackSortMode`    | `<sort_mode? string>`                                                                                          | Cycle through or set the current trail mark stack sort mode.                                                                                                                                                                                           |
| `:TrailBlazerSaveSession`                  | `<session_name? string>`                                                                                       | Save all trail mark stacks and and the current configuration to a session file. If no arguments are specified the session will be saved in the default session directory. You will find more information [here](#trail-mark-sessions).                 |
| `:TrailBlazerLoadSession`                  | `<session_name? string>`                                                                                       | Load a previous session from a session file. If no arguments are specified the session will be loaded from the default session directory. You will find more information [here](#trail-mark-sessions).                                                 |

## 📚 Documentation

You can find the technical documentation for TrailBlazer under [doc/trailblazer.nvim.txt][help]. If
you are within Neovim you can also open the documentation by running `:help trailblazer`.

## 👥 Contributing

I would like to keep TrailBlazer's code base as clean and easy to read as possible. If you would
like to contribute, please make sure to follow the following contribution guidelines and make sure
to add method documentations to your code:

### Linting

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

### Testing

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

## 💬 Feedback

Feedback is always welcome! If you would like to leave some, please use the [GitHub
Discussions][discussions]. Issues are reserved for bug reports and feature requests.

[showcase]: ../media/TrailBlazer_Showcase.gif?raw=true
[user_api]: lua/trailblazer/init.lua
[ram-def-wikipedia]: https://en.wikipedia.org/wiki/Random-access_memory
[lua]: https://www.lua.org/
[luarocks]: https://luarocks.org/
[luacheck]: https://github.com/mpeterv/luacheck
[neovim]: https://neovim.io/
[leap.nvim]: https://github.com/ggandor/leap.nvim
[harpoon]: https://github.com/ThePrimeagen/harpoon
[busted]: https://olivinelabs.com/busted/
[luassert]: https://github.com/Olivine-Labs/luassert
[plenary]: https://github.com/nvim-lua/plenary.nvim
[matcher_combinators]: https://github.com/m00qek/matcher_combinators.lua
[integration-badge]: https://github.com/LeonHeidelbach/trailblazer.nvim/actions/workflows/integration.yml/badge.svg
[integration-runs]: https://github.com/LeonHeidelbach/trailblazer.nvim/actions/workflows/integration.yml
[lua-badge]: https://img.shields.io/badge/Lua-blue.svg?style=for-the-badge&logo=lua
[gplv3-badge]: https://img.shields.io/badge/License-GPLv3-blue.svg?style=for-the-badge
[gplv3-license]: https://www.gnu.org/licenses/gpl-3.0.en.html
[foss-def-wikipedia]: https://en.wikipedia.org/wiki/Free_and_open-source_software
[foss-badge]: https://img.shields.io/badge/FOSS-✓-blue.svg?style=for-the-badge
[neovim-badge]: https://img.shields.io/badge/Neovim%200.8+-green.svg?style=for-the-badge&logo=neovim
[help]: doc/trailblazer.nvim.txt
[discussions]: https://github.com/LeonHeidelbach/trailblazer.nvim/discussions

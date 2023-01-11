# TrailBlazer.nvim

[![Integration][integration-badge]][integration-runs]

A plugin you don't deserver but need written in [Lua][lua]. Backtracking within your projects has
never been easier.

This README is incomplete! This project is WORK IN PROGRESS!

## Using

If you ever get stuck, have a look at the [documentation][help].

## Testing

TrailBlazer uses [busted][busted], [luassert][luassert] (through [plenary.nvim][plenary]) and
[matcher_combinators][matcher_combinators] to define tests in the `test/spec/` directory. If you
are planning to contribute, make sure all tests pass prior to creating a pull request.

Make sure your shell is in the `./test` directory or, if it is in the root directory,
replace `make` by `make -C ./test` in the commands below.

To initialize the dependencies run:

```bash
$ make prepare
```

To run all tests just execute

```bash
$ make test
```

[lua]: https://www.lua.org/
[busted]: https://olivinelabs.com/busted/
[luassert]: https://github.com/Olivine-Labs/luassert
[plenary]: https://github.com/nvim-lua/plenary.nvim
[matcher_combinators]: https://github.com/m00qek/matcher_combinators.lua
[integration-badge]: https://github.com/LeonHeidelbach/trailblazer.nvim/actions/workflows/integration.yml/badge.svg
[integration-runs]: https://github.com/LeonHeidelbach/trailblazer.nvim/actions/workflows/integration.yml
[neovim-test-versions]: .github/workflows/integration.yml#L17
[help]: doc/trailblazer.txt

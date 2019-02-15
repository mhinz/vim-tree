# vim-tree

This plugin integrates good old [tree(1)](http://mama.indstate.edu/users/ice/tree) into
Vim and Nvim.

## Installation

Use your favorite plugin manager. E.g. [vim-plug](https://github.com/junegunn/vim-plug):

    Plug 'mhinz/vim-tree'

Then restart Vim and `:PlugInstall`.

## Dependencies

[tree(1)](http://mama.indstate.edu/users/ice/tree) needs to be installed.

- Ubuntu/Debian: `sudo apt-get install tree`
- macOS: `brew install tree`

## Usage

There are no options and only one command: `:Tree`.

That command defaults to `tree -c -F --dirsfirst --noreport`. It takes optional
arguments that will simply be added to the default, so `:Tree -a` will run `tree
-c -F --dirsfirst --noreport -a`.

Tip: For huge directories you might want to set a limit, e.g. `:Tree -L 3`.

## Author and Feedback

If you like this plugin, star it! It's a great way of getting feedback. The same
goes for reporting issues or feature requests.

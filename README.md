# vim-tree

**vim-tree** integrates good old [tree(1)](http://mama.indstate.edu/users/ice/tree) into
Vim and Nvim for all common operating systems.

The plugin provides a single command, `:Tree`, and has no options. It is perfect
for quickly navigating and exploring complex directory hierarchies.

![vim-tree in action](./demo.svg)

## Installation

Use your favorite plugin manager. E.g. [vim-plug](https://github.com/junegunn/vim-plug):

    Plug 'mhinz/vim-tree'

Then restart Vim and `:PlugInstall`.

## Dependencies

[tree](http://mama.indstate.edu/users/ice/tree) needs to be installed.

#### Ubuntu/Debian

    $ sudo apt-get install tree

#### macOS

    $ brew install tree

#### Windows

1. Download the [win32 tree binary zip archive](http://downloads.sourceforge.net/gnuwin32/tree-1.5.2.2-bin.zip) and unzip it.
1. Move `tree.exe` from the `bin` directory to the directory containing your
   `vim.exe` or `nvim.exe`. E.g. `C:\Program Files (x86)\Vim\vim81\`.

## Usage

There are no options and only one command: `:Tree`.

That command defaults to `tree -n -F --dirsfirst --noreport`. It takes optional
arguments that will simply be added to the default, so `:Tree -a` will run `tree
-n -F --dirsfirst --noreport -a`.

Use <kbd>?</kbd> in the tree buffer to get a list of all mappings.

A few tips:

- For huge directories you might want to set a limit, e.g. `:Tree -L 3`.
- If many files have spaces in their names, `:Tree -Q` might provide more
  readable output.

---

To keep a navigator-like window open:

```vim
:leftabove 40vnew | Tree
```

Then use `p` to open the current entry in the previous window.

---

To fold on directories:

```vim
autocmd FileType tree setlocal foldmethod=expr
```

## Customization

- The tree buffer sets the `tree` filetype.
- `tree#GetPath()` returns the path of the current entry.

Stupid example:

```vim
autocmd FileType tree
      \ autocmd CursorMoved <buffer> execute 'pedit' tree#GetPath()
```

Now, every time you move the cursor to a file, it will be shown in the preview
window.

## Author and Feedback

If you like this plugin, star it! It's a great way of getting feedback. The same
goes for reporting issues or feature requests.

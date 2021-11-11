## Overview
The `quickfix` window is great, but it would be nice to get some context around
our searches. This plugin adds `rg` output to a side buffer with quick
navigation mappings using comfortable Vim conventions.

![Simple Demo](side-search-demo.gif)

## Features
- step through `rg` output instead of `quickfix` output
- syntax highlighting of `rg` output
- mappable to search current word under the cursor
- configurable `g:side_search_prg` similar to `grepprg`
- vertical or horizontal split output via `g:side_search_splitter`

## Buffer Mappings
```
n/N             - Cursor to next/prev
<C-n>/<C-p>     - Open next/prev
<CR>|<DblClick> - Open at cursor
<C-w><CR>       - Open and jump to window
qf              - :grep! to Quickfix
```

## Prerequisites
We rely on [The Silver Searcher](https://github.com/ggreer/the_silver_searcher)
to perform our file/text searches for us. Theoretically, any program which has
the same output could also work, but that we only test using `rg` output.

To install `rg` command on OSX:

```sh
brew install ripgrep
```

Refer to [Ripgrep](https://github.com/BurntSushi/ripgrep) for more instructions.


## Global Configuration
```vim
" How should we execute the search?
" --heading and --stats are required!
let g:side_search_prg = 'rg --word-regexp'
  \. " --ignore='*.js.map'"
  \. " --heading --stats -B 1 -A 4"
  \. " --case-sensitive"
  \. " --line-number"

" Can use `vnew` or `new`
let g:side_search_splitter = 'vnew'

" I like 40% splits, change it if you don't
let g:side_search_split_pct = 0.4
```

## Suggested Mapping
```vim
" SideSearch current word and return to original window
nnoremap <Leader>ss :SideSearch <C-r><C-w><CR> | wincmd p

" Create an shorter `SS` command
command! -complete=file -nargs=+ SS execute 'SideSearch <args>'

" or command abbreviation
cabbrev SS SideSearch
```

## FAQ

> How to search for multi-word terms?

Surround terms with double quotes

```
:SideSearch "cats and dogs"
```

> How to pass extra args to `rg`?

Just do it :)
```
:SideSearch -t js MyAwesomeComponent
```

> What happened to using The Silver Searcher?

The `ag` program was deprecated back in 2016. https://github.com/rking/ag.vim/issues/124
We moved to `ripgrep` as a modern alternative.
Ultimately, any program can be used by setting `g:side_search_prg` and has output matching out syntax highlighter should
work.


> How to change project root detection?

This plugin uses various methods for attempting to find the project root. [See guessProjectRoot for more details.](https://github.com/ddrscott/vim-side-search/blob/master/plugin/side-search.vim#L158)
To disable the guessing and force an explicit project directory create the following function in your `$MYVIMRC`:

```vim
function! FindRootDirectory()
  return getcwd()
endfunction
```

> How to search in a root-relative subdirectory?

Add this to your configuration:
```vim
function! SideSearchRestrictedAndRelative(query, ...) abort
  let l:subdir = get(a:, 1, '')
  let l:subdir = (l:subdir == '' ? '' : '/') . l:subdir
  call SideSearch(shellescape(a:query, 1), l:subdir)
endfunction
command! -complete=file -nargs=+ SideSearchRestrictedAndRelative call SideSearchRestrictedAndRelative(<f-args>)
```

To search in a root-relative directory, do: `:SideSearchRestrictedAndRelative some\ query some/root-relative/directory`.

Having the command abbreviation `cabbrev SS SideSearchRestrictedAndRelative` in config would make this shorter: `:SS some\ query some/root-relative/directory`.

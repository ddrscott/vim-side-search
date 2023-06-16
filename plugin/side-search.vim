" Finds the largest window based on area.
" If the current window is the largest
" it will pick the next largest window.
" Return: the winnr() of the largest window.
function! s:find_largest_winnr() abort
  let largest = 0
  let size = 0
  let current = winnr()
  let i = winnr('$')
  while i > 0
    let area = winheight(i) * winwidth(i)
    if i != current && area >= size
      let largest = i
      let size = area
    endif
    let i -= 1
  endwhile
  return largest
endfunction

" Open `src` file in the largest window based
" on s:find_largest_winnr()
function! s:open_largest(src) abort
  "execute '' . s:find_largest_winnr() . 'wincmd w'
  execute '' . s:sidesearch_caller_window() . 'wincmd w'
  if bufloaded(a:src)
    execute 'buffer ' . a:src
  else
    execute 'edit ' . a:src
  endif
endfunction

" Returns: calc percentage column in Vim window
function! s:percent_columns(columns, pct) abort
  return printf('%.f', a:columns * a:pct)
endfunction

" Returns: calc percentage lines in Vim window
function! s:percent_lines(lines, pct) abort
  return printf('%.f', a:lines * a:pct)
endfunction

" Uses `b:my_buffer` to identify this as a side_search buffer.
" Returns: `winnr` that contains the side_search managed buffer.
function! s:my_buffer_winnr() abort
  let i = winnr('$')
  let my_buffer_id = expand('\<SID>')
  while i > 0
    if getbufvar(winbufnr(i), 'my_buffer') == my_buffer_id
      return i
    end
    let i -= 1
  endwhile
  return -1
endfunction

function! s:sidesearch_caller_window() abort
  let i = winnr('$')
  let my_buffer_id = expand('\<SID>')
  while i > 0
    if getbufvar(winbufnr(i), 'my_buffer') == my_buffer_id
      let callerwinidx = getbufvar(winbufnr(i), 'callerwindow') 
      return callerwinidx
    end
    let i -= 1
  endwhile
  return -1
endfunction

function! s:defaults() abort
  if !exists('g:side_search_prg')
    if executable('rg')
      let g:side_search_prg = 'rg --word-regexp --heading --stats -C 2 --case-sensitive --line-number'
    else
      let g:side_search_prg = 'ag --word-regexp --heading --stats -C 2 --group'
    endif
  endif
  if !exists('g:side_search_splitter')
    let g:side_search_splitter = 'vnew'
  endif
  if !exists('g:side_search_split_pct')
    let g:side_search_split_pct = 0.4
  endif
endfunction

" Creates a new buffer and `setlocal` settings to
" turn off decorations and make it a non-editable scratch buffer.
function! s:new_buffer(splitter, split_pct, callerwindow_id) abort
  let callerwindow_width = winwidth(0)
  let callerwindow_height = winheight(0)
  execute a:splitter
  if a:splitter == 'vnew'
    execute 'vert resize ' . s:percent_columns(callerwindow_width, a:split_pct)
    execute 'wincmd x'
    execute 'wincmd w'
  else
    execute s:percent_lines(callerwindow_height, a:split_pct) . 'wincmd_'
  endif
  setlocal nobuflisted nolist nonumber norelativenumber noswapfile nowrap
  setlocal bufhidden=wipe foldcolumn=0 textwidth=0 buftype=nofile scrolloff=5 cursorline winfixheight winfixwidth
  let b:my_buffer = expand('\<SID>')
  let b:callerwindow = a:callerwindow_id
endfunction

" Setup custom mappings for the buffer
function! s:custom_mappings() abort
  nnoremap <buffer> <silent> <C-n> :exec "normal! nzz"<CR>:call <SID>preview_main()<CR>
  nnoremap <buffer> <silent> <C-p> :exec "normal! Nzz"<CR>:call <SID>preview_main()<CR>
  nnoremap <buffer> <silent> <CR> :call <SID>preview_main()<CR>
  nnoremap <buffer> <silent> <2-LeftMouse> :call <SID>preview_main()<CR>
  nnoremap <buffer> <silent> <C-w><CR> :call <SID>open_main()<CR>
  nnoremap <buffer> <silent> qf :silent exec 'grep!' b:escaped<CR>
endfunction

" Appends header guide to buffer
function! s:append_guide() abort
  call append(0, [
        \ '# Buffer Mappings:',
        \ '# n/N             - Cursor to next/prev',
        \ '# <C-n>/<C-p>     - Open next/prev',
        \ '# <CR>|<DblClick> - Open at cursor',
        \ '# <C-w><CR>       - Open and jump to window',
        \ '# qf              - :grep! to Quickfix',
        \ ])
  " jump to last
  call cursor(line('$'), 0)
endfunction

" Find the line number and file from current cursor position
" and open the found location using `open_largest`
" Warning: This is highly targeted for `ag's` command output.
"          If `ag` changes, this will surely break. Sorry.
function! s:open_cursor_location(exec_after) abort
  " get digits from the beginning of the line
  let lnum = matchstr(getline('.'), '\v^\d+')
  if lnum
    " flags: b = search [b]ackwards
    "        n = no move cursor
    let file_pos = search('\v^(\d+[:-]|--)@!.+$', 'bn')
    if file_pos
      let file_path = getline(file_pos)
      call s:open_largest(file_path)
      execute 'normal! ' . lnum . expand('Gzz')
      execute 'normal! zv'
      if a:exec_after != ''
        execute a:exec_after
      endif
    endif
  endif
endfunction

function! s:preview_main() abort
  call s:open_cursor_location('wincmd p') 
endfunction

function! s:open_main() abort
  call s:open_cursor_location('') 
endfunction

" Parses `ag` output for the 'matches' line at the end
function! s:parse_matches() abort
  let matcher = '\v^(\d+) match(es)?'
  let pos = search(matcher, 'bn')
  if pos > 1
    return getline(pos)
  endif
  return 'no matches'
endfunction

" Helper to get the `winnr` of the SideSearch window.
" I somewhat prefer this way over maintaining a g:variable.
function! SideSearchWinnr()
  return s:my_buffer_winnr()
endfunction

function! SideSearchCallingWindowNr()
  return s:sidesearch_caller_window()
endfunction

function! s:guessProjectRoot()
  if exists("*FindRootDirectory")
    let l:root = FindRootDirectory()
    if l:root != ''
      return l:root
    endif
  endif

  let l:cwd = getcwd()
  let l:maxdistance = len(split(l:cwd, '/')) - 2
  let l:searchdir = ''

  while len(split(l:searchdir, '/')) < l:maxdistance
    for l:marker in ['.rootdir', '.git', '.hg', '.svn', 'bzr', '_darcs', 'build.xml']
      let l:dir = l:searchdir.l:marker
      if filereadable(l:dir) || isdirectory(l:dir)
        return l:searchdir
      endif
    endfor
    let l:searchdir = '../'.l:searchdir
  endwhile

  return l:cwd
endfunction

" The public facing function.
" Accept 1 or 2 arguments which basically get passed directly
" to the `ag` command.
"
" This will name the buffer the search term so it's easier to identify.
" After opening the search results, the cursor should remain in it's
" original position.
function! SideSearch(term, ...) abort
  call s:defaults()

  let found = SideSearchWinnr()
  " save current winnr so that i can set it later on in the sidesearch win
  let callerwindow_id = winnr()
  if found > -1
    execute '' . found . 'wincmd w'
    setlocal modifiable
    execute '0,$d'
  else
    call s:new_buffer(g:side_search_splitter, g:side_search_split_pct, callerwindow_id)
    call s:custom_mappings()
  endif

  call s:append_guide()

  let b:escaped = shellescape(a:term)
  let b:cmd = g:side_search_prg . ' ' . b:escaped

  " Guess the directory if value path is not provided as last argument
  if len(a:000) == 0 || isdirectory(a:000[-1]) == 0
    let l:cwd = s:guessProjectRoot()
    let b:cmd = b:cmd . ' ' . join(a:000, ' ') . ' ' . fnamemodify(l:cwd, ':p')
  else
    let b:cmd = b:cmd . ' ' . join(a:000[0:-2], ' ') . ' ' . fnamemodify(a:000[-1], ':p')
  endif

  " echom 'a:term => ' . a:term
  " echom 'b:cmd => '.b:cmd
  silent execute 'read!' b:cmd

  " name the buffer something useful
  silent execute 'file [SS ' . b:escaped . ', ' . s:parse_matches() . ']'

  " save search term in search register
  let @/ = a:term

  " 1. go to top of file
  " 2. forward search the term
  silent! execute "normal! ggn"

  " Turn on search highlight. Must be done this way.
  " Thanks: https://github.com/rking/ag.vim/blob/master/autoload/ag.vim#L153
  call feedkeys(":let &hlsearch=1 \| echo \<CR>", 'n')

  " set this stuff after execute for better performance
  setlocal nomodifiable filetype=rg
endfunction

" Create a command to call SideSearch
command! -complete=file -nargs=+ SideSearch call SideSearch(<f-args>)

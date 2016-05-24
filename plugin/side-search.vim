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

function! s:open_largest(src) abort
  execute '' . s:find_largest_winnr() . 'wincmd w'
  execute 'edit ' . a:src
endfunction

function! s:percent_columns(pct) abort
  return printf('%.f', &columns * a:pct)
endfunction

function! s:exists_window_prefix(prefix) abort
  let i = winnr('$')
  while i > 0
    if stridx(bufname(winbufnr(i)), a:prefix) > -1
      return i
    end
    let i -= 1
  endwhile
  return -1
endfunction

function! s:side_search_defaults() abort
  if !exists('g:ag_flags')
    let g:ag_flags = ' --word-regexp --heading --stats -C 2'
  endif
  if !exists('g:side_search_splitter')
    let g:side_search_splitter = 'vnew'
  endif
  if !exists('g:side_search_width_pct')
    let g:side_search_width_pct = 0.4
  endif
endfunction

function! s:side_search_new_buffer() abort
  execute g:side_search_splitter
  execute '' . s:percent_columns(g:side_search_width_pct) . 'wincmd|'
  setlocal nobuflisted nolist nonumber norelativenumber noswapfile wrap
  setlocal bufhidden=wipe foldcolumn=0 textwidth=0 buftype=nofile scrolloff=5 cursorline winfixheight winfixwidth
  nnoremap <buffer> <silent> <CR> :call <SID>side_open()<CR>
endfunction

function! s:side_search(...) abort
  call s:side_search_defaults()

  let file_prefix = '[ag '
  let found = s:exists_window_prefix(file_prefix)
  if found > -1
    execute '' . found . 'wincmd w'
    setlocal modifiable
    execute '0,$d'
  else
    call s:side_search_new_buffer()
  endif
  " name the buffer something useful
  silent execute 'file ' . file_prefix . a:1 . ']'

  " execute showing summary of stuff read (without silent)
  execute 'read !ag ' . g:ag_flags . ' ' . join(a:000, ' ')

  " set this stuff after execute for better performance
  setlocal nomodifiable filetype=ag
  let @/=a:1
  normal! <C-w>p
endfunction

function! s:side_open() abort
  let lnum = matchstr(getline('.'), '\v^\d+') 
  if lnum
    let file_pos = search('\v^(\d+[:-]|--)@!.+$', 'bn')
    if file_pos
      let file_path = getline(file_pos)
      echo file_path . ' +' . lnum
      call s:open_largest(file_path)
      execute 'normal! ' . lnum . expand('Gzz')
      wincmd p
    endif
  endif
endfunction

command! -complete=file -nargs=+ SideSearch call <SID>side_search(<f-args>)

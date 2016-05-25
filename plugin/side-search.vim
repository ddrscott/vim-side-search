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
  execute '' . s:find_largest_winnr() . 'wincmd w'
  execute 'edit ' . a:src
endfunction

" Returns: calc percentage column in Vim window
function! s:percent_columns(pct) abort
  return printf('%.f', &columns * a:pct)
endfunction

" Returns: calc percentage lines in Vim window
function! s:percent_lines(pct) abort
  return printf('%.f', &lines * a:pct)
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

function! s:defaults() abort
  if !exists('g:side_search_prg')
    let g:side_search_prg = 'ag --word-regexp --heading --stats -C 2'
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
function! s:new_buffer(splitter, split_pct) abort
  execute a:splitter
  if a:splitter == 'vnew'
    execute s:percent_columns(a:split_pct) . 'wincmd|'
  else
    execute s:percent_lines(a:split_pct) . 'wincmd_'
  endif
  setlocal nobuflisted nolist nonumber norelativenumber noswapfile wrap
  setlocal bufhidden=wipe foldcolumn=0 textwidth=0 buftype=nofile scrolloff=5 cursorline winfixheight winfixwidth
  let b:my_buffer = expand('\<SID>')
endfunction

" Setup custom mappings for the buffer
function! s:custom_mappings() abort
  nnoremap <buffer> <silent> <CR> :call <SID>side_open()<CR>
  nnoremap <buffer> <silent> <C-n> :exec "normal! nzz"<CR>:call <SID>side_open()<CR>
  nnoremap <buffer> <silent> <C-p> :exec "normal! Nzz"<CR>:call <SID>side_open()<CR>
endfunction

" Find the line number and file from current cursor position
" and open the found location using `open_largest`
" Warning: This is highly targeted for `ag's` command output.
"          If `ag` changes, this will surely break. Sorry.
function! s:side_open() abort
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
      wincmd p
    endif
  endif
endfunction

" Parses `ag` output for the 'matches' line at the end
function! s:parse_matches() abort
  let matcher = '\v^(\d+) match(es)?' 
  let pos = search(matcher, 'bn')
  if pos
    return getline(pos)
  endif
  return ''
endfunction

" Helper to get the `winnr` of the SideSearch window.
" I somewhat prefer this way over maintaining a g:variable.
function SideSearchWinnr()
  return s:my_buffer_winnr()
endfunction

" The public facing function.
" Accept 1 or 2 arguments which basically get passed directly
" to the `ag` command.
" 
" This will name the buffer the search term so it's easier to identify.
" After opening the search results, the cursor should remain in it's
" original position.
function! SideSearch(...) abort
  call s:defaults()

  let found = SideSearchWinnr() 
  if found > -1
    execute '' . found . 'wincmd w'
    setlocal modifiable
    execute '0,$d'
  else
    call s:new_buffer(g:side_search_splitter, g:side_search_split_pct)
    call s:custom_mappings()
  endif

  " execute showing summary of stuff read (without silent)
  execute 'read!' g:side_search_prg join(a:000, ' ')

  " name the buffer something useful
  silent execute 'file [SS '.a:1.', '.s:parse_matches().']'

  " set this stuff after execute for better performance
  setlocal nomodifiable filetype=ag

  " save search term in search register
  let @/ = a:1

  " 1. go to top of file
  " 2. forward search the term
  execute "normal! ggn"
endfunction

" Create a command to call SideSearch
" Warning: `set hlsearch` must be here. I don't know why it doesn't work when I
"          put it into SideSearch function.
command! -complete=file -nargs=+ SideSearch call SideSearch(<f-args>) | set hlsearch
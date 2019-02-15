let s:default_cmd   = 'tree -c -F --dirsfirst --noreport'
let s:default_chars = '[^│─├└  ]'

function! tree#Tree(options) abort
  enew
  execute 'silent %!'.get(g:, 'tree_cmd', s:default_cmd).' '.a:options
  silent! %substitute/ / /g
  2
  setlocal nomodified buftype=nofile bufhidden=wipe
  let &l:statusline = ' tree '.getcwd()
  call s:set_mappings()
  augroup tree
    autocmd!
    autocmd CursorMoved <buffer> call s:on_cursormoved()
  augroup END
  echo '(q)uit (e)dit (s)plit (v)split (t)abedit'
  set filetype=tree
endfunction

function! s:set_mappings() abort
  nnoremap <silent><buffer> q :bwipeout<cr>
  nnoremap <silent><buffer> e :execute 'edit'    tree#GetPath()<cr>
  nnoremap <silent><buffer> s :execute 'split'   tree#GetPath()<cr>
  nnoremap <silent><buffer> v :execute 'vsplit'  tree#GetPath()<cr>
  nnoremap <silent><buffer> t :execute 'tabedit' tree#GetPath()<cr>
  nnoremap <silent><buffer> h :call tree#go_back()<cr>
  nnoremap <silent><buffer> j :call tree#go_down()<cr>
  nnoremap <silent><buffer> k :call tree#go_up()<cr>
  nnoremap <silent><buffer> l :call tree#go_forth()<cr>
endfunction

function! tree#go_up() abort
  let [line, col] = [line('.')-1, virtcol('.')-1]
  while line > 1
    let c = strwidth(matchstr(getline(line), '.\{-}\ze'.s:default_chars))
    if c == col
      execute line
      return 1
    endif
    let line -= 1
  endwhile
endfunction

function! tree#go_down() abort
  let [line, col] = [line('.')+1, virtcol('.')-1]
  let last_line = line('$')
  while line <= last_line
    let c = strwidth(matchstr(getline(line), '.\{-}\ze'.s:default_chars))
    if c == col
      execute line
      return 1
    endif
    let line += 1
  endwhile
endfunction

function! tree#go_back() abort
  let [line, col] = [line('.')-1, virtcol('.')-1]
  while line > 1
    let c = strwidth(matchstr(getline(line), '.\{-}\ze'.s:default_chars))
    if c < col
      execute line
      return 1
    endif
    let line -= 1
  endwhile
endfunction

function! tree#go_forth() abort
  let [line, col] = [line('.')+1, virtcol('.')-1]
  let last_line = line('$')
  while line <= last_line
    let c = strwidth(matchstr(getline(line), '.\{-}\ze'.s:default_chars))
    if c > col
      execute line
      return 1
    endif
    let line += 1
  endwhile
endfunction

function! tree#GetPath() abort
  let path = ''
  let [line, col] = [line('.'), col('.')]
  while line > 1
    let c = match(getline(line), s:default_chars)
    if c < col
      let path = matchstr(getline(line)[c:], '.*') . path
      let col = c
    endif
    let line -= 1
  endwhile
  return path
endfunction

function! s:on_cursormoved() abort
  normal! 0
  if line('.') <= 1 | 2 | endif
  call search(s:default_chars, '', line('.'))
endfunction

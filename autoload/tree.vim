let s:default_cmd   = 'tree -c -F --dirsfirst --noreport'
let s:default_chars = '[^│─├└  ]'

function! tree#Tree(options) abort
  enew
  execute 'silent %!'.get(g:, 'tree_cmd', s:default_cmd).' '.a:options
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
  nnoremap <silent> q :bwipeout<cr>
  nnoremap <silent> e :execute 'edit'    tree#GetPath()<cr>
  nnoremap <silent> s :execute 'split'   tree#GetPath()<cr>
  nnoremap <silent> v :execute 'vsplit'  tree#GetPath()<cr>
  nnoremap <silent> t :execute 'tabedit' tree#GetPath()<cr>
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
  call search(s:default_chars, '', line('.'))
endfunction

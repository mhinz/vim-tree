let s:default_cmd = 'tree -c -F --dirsfirst --noreport'

function! tree#Tree(options) abort
  enew
  execute 'silent %!'.get(g:, 'tree_cmd', s:default_cmd).' '.a:options
  setlocal nomodified buftype=nofile bufhidden=wipe
  let &l:statusline = ' tree '.getcwd()
  nnoremap q :silent bwipeout<cr>
  augroup tree
    autocmd!
    autocmd CursorMoved <buffer> call s:on_cursormoved()
  augroup END
  set filetype=tree
endfunction

function! tree#GetPath() abort

endfunction

function! s:on_cursormoved() abort
  normal! 0
  call search('[^│─├└  ]', 'z', line('.'))
endfunction

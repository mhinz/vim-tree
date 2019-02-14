if exists('g:loaded_tree')
  finish
endif
let g:loaded_tree = 1

function! Tree(options) abort
  enew
  execute 'silent %!'.get(g:, 'tree_cmd', 'tree -c --dirsfirst').' '.a:options
  setlocal nomodified buftype=nofile bufhidden=wipe
  let &l:statusline = ' tree '.getcwd()
  nnoremap q :silent bwipeout<cr>
  autocmd CursorMoved <buffer> call s:on_cursormoved()
  set filetype=tree
endfunction

function! s:on_cursormoved() abort
  normal! 0
  call search('[^│─├└  ]', 'z', line('.'))
endfunction

command -nargs=* Tree call Tree(<q-args>)

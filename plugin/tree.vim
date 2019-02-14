if exists('g:loaded_tree')
  finish
endif
let g:loaded_tree = 1

command -nargs=* Tree call Tree(<q-args>)

function! Tree(options) abort
  enew
  execute 'silent %!'.get(g:, 'tree_cmd', 'tree -c --dirsfirst').' '.a:options
  setlocal nomodified buftype=nofile bufhidden=wipe
  let &l:statusline = ' tree '.getcwd()
  nnoremap q :silent bwipeout<cr>
endfunction

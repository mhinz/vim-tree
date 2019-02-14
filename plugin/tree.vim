if exists('g:loaded_tree')
  finish
endif
let g:loaded_tree = 1

command -nargs=* Tree call tree#Tree(<q-args>)

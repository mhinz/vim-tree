if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

let s:save_cpo = &cpo
set cpo&vim

" prepare logging with https://github.com/hupfdule/log.vim (if available)
silent! let s:log = log#getLogger(expand('<sfile>:t') . ':b'.bufnr().':w'.winnr())

silent! call s:log.info("New tree for directory " . getcwd())

function! s:set_mappings() abort
  nnoremap <silent><buffer><nowait> ?     :call tree#Help()<cr>
  nnoremap <silent><buffer><nowait> q     :bwipeout \| echo<cr>
  nnoremap <silent><buffer><nowait> c     :call tree#cd_to()<cr>
  nnoremap <silent><buffer><nowait> H     :call tree#cd_up()<cr>
  nnoremap <silent><buffer><nowait> b     :call tree#cd_back()<cr>
  nnoremap <silent><buffer><nowait> e     :call tree#edit_entry('e')<cr>
  nnoremap <silent><buffer><nowait> p     :execute 'wincmd p \| edit' tree#GetPath()<cr>
  nnoremap <silent><buffer><nowait> s     :call tree#edit_entry('s')<cr>
  nnoremap <silent><buffer><nowait> v     :call tree#edit_entry('v')<cr>
  nnoremap <silent><buffer><nowait> t     :call tree#edit_entry('t')<cr>
  nnoremap <silent><buffer><nowait> r     :call tree#reload()<cr>
  nnoremap <silent><buffer><nowait> h     :call tree#go_back()<cr>
  nnoremap <silent><buffer><nowait> l     :call tree#go_forth()<cr>
  nnoremap <silent><buffer><nowait> <C-K> :call tree#go_up()<cr>
  nnoremap <silent><buffer><nowait> <C-J> :call tree#go_down()<cr>
  nnoremap <silent><buffer><nowait> x     :call tree#open_term()<cr>
  nnoremap <silent><buffer><nowait> n     :call <SID>search_again()<cr>
  nnoremap <silent><buffer><nowait> du    :call tree#calc_dir_sizes()<cr>
  nnoremap <silent><buffer><nowait> dU    :%call tree#calc_dir_sizes()<cr>
  xnoremap <silent><buffer><nowait> du    :call tree#calc_dir_sizes()<cr>
endfunction

function! s:on_cursormoved() abort
  silent! call s:log.trace("s:on_cursormoved()")
  normal! 0
  if line('.') <= 1 && line('$') > 1 | 2 | endif
  let ln= search(g:tree#entry_start_regex.'\zs', '', line('.'))
  if virtcol('.') >= winwidth(0) / 2
    execute 'normal! zs'.(winwidth(0)/4).'zh'
  else
    normal! ze
  endif
endfunction

function! s:on_dirchanged() abort
  silent! call s:log.trace("s:on_dirchanged(): v:event = ". string(v:event))
  if !has("nvim") || !v:event['changed_window']
    silent! call s:log.debug("s:on_dirchanged(): reloading tree for directory ".v:event['cwd'])
    call tree#Tree(b:last_options)
  endif
endfunction

function! s:search_again() abort
  let line = line('.')
  try
    execute 'normal! n'
  catch /^Vim\%((\a\+)\)\=:E486:/
    let errormsg = substitute(v:exception, '^Vim\%((\a\+)\)\=:', '', '')
    echohl ErrorMsg | echo errormsg | echohl Normal
    return
  endtry

  " if a search was found on the same line, search again from the next line
  if line('.') ==# line
    try
      execute 'normal! n'
    catch /^Vim\%((\a\+)\)\=:E486:/
      let errormsg = substitute(v:exception, '^Vim\%((\a\+)\)\=:', '', '')
      echohl ErrorMsg | echo errormsg | echohl Normal
      return
    endtry
  endif
endfunction

let b:prev_paths = []
let b:prefix_and_path_cache = {}
let b:path_cache = {}

setlocal nomodified buftype=nofile bufhidden=hide nowrap nonumber foldcolumn=0 foldtext=foldtext#foldtext()
call s:set_mappings()

if get(g:, 'tree_enable_folding', '0')
  setlocal foldlevel=1
  setlocal foldmethod=expr
  setlocal foldexpr=tree#get_foldlevel(v:lnum)
  call foldtext#set_fold_mappings()
endif

augroup tree
  autocmd! * <buffer>
  autocmd CursorMoved <buffer> call s:on_cursormoved()
  if exists('##DirChanged')
    autocmd DirChanged <buffer> call s:on_dirchanged()
  endif
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo


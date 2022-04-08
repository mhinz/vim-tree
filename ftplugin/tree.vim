if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

let s:save_cpo = &cpo
set cpo&vim

function! s:set_mappings() abort
  nnoremap <silent><buffer><nowait> ? :call tree#Help()<cr>
  nnoremap <silent><buffer><nowait> q :bwipeout \| echo<cr>
  nnoremap <silent><buffer><nowait> c :call tree#cd_to()<cr>
  nnoremap <silent><buffer><nowait> H :call tree#cd_up()<cr>
  nnoremap <silent><buffer><nowait> b :call tree#cd_back()<cr>
  nnoremap <silent><buffer><nowait> e :execute 'edit'             tree#GetPath()<cr>
  nnoremap <silent><buffer><nowait> p :execute 'wincmd p \| edit' tree#GetPath()<cr>
  nnoremap <silent><buffer><nowait> s :execute 'split'            tree#GetPath()<cr>
  nnoremap <silent><buffer><nowait> v :execute 'vsplit'           tree#GetPath()<cr>
  nnoremap <silent><buffer><nowait> t :execute 'tabedit'          tree#GetPath()<cr>
  nnoremap <silent><buffer><nowait> r :call tree#reload()<cr>
  nnoremap <silent><buffer><nowait> h :call tree#go_back()<cr>
  nnoremap <silent><buffer><nowait> l :call tree#go_forth()<cr>
  nnoremap <silent><buffer><nowait> K :call tree#go_up()<cr>
  nnoremap <silent><buffer><nowait> J :call tree#go_down()<cr>
  nnoremap <silent><buffer><nowait> x :call tree#open_term()<cr>
endfunction

function! s:on_cursormoved() abort
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
  if !v:event['changed_window']
    call tree#Tree(b:last_options)
  endif
endfunction

let b:prev_paths = []
let b:prefix_and_path_cache = {}
let b:path_cache = {}

setlocal nomodified buftype=nofile bufhidden=wipe nowrap nonumber foldcolumn=0 foldtext=foldtext#foldtext()
set foldexpr=tree#get_foldlevel(v:lnum)
call s:set_mappings()
call foldtext#set_fold_mappings()

augroup tree
  autocmd! * <buffer>
  autocmd CursorMoved <buffer> call s:on_cursormoved()
  if exists('##DirChanged')
    autocmd DirChanged <buffer> call s:on_dirchanged()
  endif
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo


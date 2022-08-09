if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

let s:save_cpo = &cpo
set cpo&vim

" prepare logging with https://github.com/hupfdule/log.vim (if available)
silent! let s:log = log#getLogger(expand('<sfile>:t') . ':b'.bufnr().':w'.winnr())

silent! call s:log.info("New tree for directory " . getcwd())

function! s:prepare_pluginhelp() abort
  nnoremap <silent><buffer><nowait> <Plug>(TreeHelp)             :call pluginhelp#show({
    \ 'help_topic': 'tree',
    \ 'mappings':  [
    \    {'plugmap': '<Plug>(TreeHelp)',             'desc': 'this help'},
    \    {'plugmap': '<Plug>(TreeClose)',            'desc': 'wipeout tree buffer'},
    \    {'plugmap': '<Plug>(TreeCdTo)',             'desc': 'go to directory'},
    \    {'plugmap': '<Plug>(TreeCdUp)',             'desc': 'go back one directory'},
    \    {'plugmap': '<Plug>(TreeCdBack)',           'desc': 'go up to next entry of the same level'},
    \    {'plugmap': '<Plug>(TreeEdit)',             'desc': 'go down to next entry of the same level'},
    \    {'plugmap': '<Plug>(TreeEditInPrevWindow)', 'desc': 'reload tree with the same options'},
    \    {'plugmap': '<Plug>(TreeEditInSplit)',      'desc': ':lcd into current entry and rerun :Tree'},
    \    {'plugmap': '<Plug>(TreeEditInVSplit)',     'desc': ':lcd into the parent directory and rerun :Tree'},
    \    {'plugmap': '<Plug>(TreeEditInTab)',        'desc': ':lcd back into the previous directory and rerun :Tree'},
    \    {'plugmap': '<Plug>(TreeReload)',           'desc': ':edit current entry'},
    \    {'plugmap': '<Plug>(TreeToParent)',         'desc': ':edit current entry in previous (last accessed) window'},
    \    {'plugmap': '<Plug>(TreeToChild)',          'desc': ':split current entry'},
    \    {'plugmap': '<Plug>(TreePrevSibling)',      'desc': ':vsplit current entry'},
    \    {'plugmap': '<Plug>(TreeNextSibling)',      'desc': ':tabedit current entry'},
    \    {'plugmap': '<Plug>(TreeTerm)',             'desc': ':terminal on current entry'},
    \    {'plugmap': '<Plug>(TreeSearchAgain)',      'desc': 'wrapper around "n" to not break searching again'},
    \    {'plugmap': '<Plug>(TreeCalcAllDirSizes)',  'desc': 'recalculate all directory sizes'},
    \    {'plugmap': '<Plug>(TreeCalcDirSize)',      'desc': 'recalculate directory sizes'},
    \  ],
    \ 'settings':  [
    \    {'setting': 'g:tree_enable_folding',      'desc': 'Enable folding of directory entries'},
    \    {'setting': 'g:tree_default_options',     'desc': 'Options to always provide to the "tree" command'},
    \    {'setting': 'g:tree_remember_fold_state', 'desc': 'Remember the fold state on reload (possibly slow)'},
    \  ],
    \ })<cr>
endfunction
function! s:set_mappings() abort
  " FIXME: Write a function for specifying <Plug>-name, action, default mapping, description in one place?
  "        Problem is that we have to specify everything as string then.
  nnoremap <silent><buffer><nowait> <Plug>(TreeHelp)             :call tree#Help()<cr>
  nnoremap <silent><buffer><nowait> <Plug>(TreeClose)            :bwipeout \| echo<cr>
  nnoremap <silent><buffer><nowait> <Plug>(TreeCdTo)             :call tree#cd_to()<cr>
  nnoremap <silent><buffer><nowait> <Plug>(TreeCdUp)             :call tree#cd_up()<cr>
  nnoremap <silent><buffer><nowait> <Plug>(TreeCdBack)           :call tree#cd_back()<cr>
  nnoremap <silent><buffer><nowait> <Plug>(TreeEdit)             :call tree#edit_entry('e')<cr>
  nnoremap <silent><buffer><nowait> <Plug>(TreeEditInPrevWindow) :execute 'wincmd p \| edit' tree#GetPath()<cr>
  nnoremap <silent><buffer><nowait> <Plug>(TreeEditInSplit)      :call tree#edit_entry('s')<cr>
  nnoremap <silent><buffer><nowait> <Plug>(TreeEditInVSplit)     :call tree#edit_entry('v')<cr>
  nnoremap <silent><buffer><nowait> <Plug>(TreeEditInTab)        :call tree#edit_entry('t')<cr>
  nnoremap <silent><buffer><nowait> <Plug>(TreeReload)           :call tree#reload()<cr>
  nnoremap <silent><buffer><nowait> <Plug>(TreeToParent)         :call tree#go_back()<cr>
  nnoremap <silent><buffer><nowait> <Plug>(TreeToChild)          :call tree#go_forth()<cr>
  nnoremap <silent><buffer><nowait> <Plug>(TreePrevSibling)      :call tree#go_up()<cr>
  nnoremap <silent><buffer><nowait> <Plug>(TreeNextSibling)      :call tree#go_down()<cr>
  nnoremap <silent><buffer><nowait> <Plug>(TreeTerm)             :call tree#open_term()<cr>
  nnoremap <silent><buffer><nowait> <Plug>(TreeSearchAgain)      :call <SID>search_again()<cr>
  nnoremap <silent><buffer><nowait> <Plug>(TreeCalcDirSize)      :call tree#calc_dir_sizes()<cr>
  nnoremap <silent><buffer><nowait> <Plug>(TreeCalcAllDirSizes)  :%call tree#calc_dir_sizes()<cr>
  xnoremap <silent><buffer><nowait> <Plug>(TreeCalcDirSize)      :call tree#calc_dir_sizes()<cr>
  if exists('g:loaded_pluginhelp')
    call s:prepare_pluginhelp()
  endif

  nmap <silent><buffer><nowait> g?    <Plug>(TreeHelp)
  nmap <silent><buffer><nowait> q     <Plug>(TreeClose)
  nmap <silent><buffer><nowait> c     <Plug>(TreeCdTo)
  nmap <silent><buffer><nowait> H     <Plug>(TreeCdUp)
  nmap <silent><buffer><nowait> b     <Plug>(TreeCdBack)
  nmap <silent><buffer><nowait> e     <Plug>(TreeEdit)
  nmap <silent><buffer><nowait> p     <Plug>(TreeEditInPrevWindow)
  nmap <silent><buffer><nowait> s     <Plug>(TreeEditInSplit)
  nmap <silent><buffer><nowait> v     <Plug>(TreeEditInVSplit)
  nmap <silent><buffer><nowait> t     <Plug>(TreeEditInTab)
  nmap <silent><buffer><nowait> r     <Plug>(TreeReload)
  nmap <silent><buffer><nowait> h     <Plug>(TreeToParent)
  nmap <silent><buffer><nowait> l     <Plug>(TreeToChild)
  nmap <silent><buffer><nowait> <C-K> <Plug>(TreePrevSibling)
  nmap <silent><buffer><nowait> <C-J> <Plug>(TreeNextSibling)
  nmap <silent><buffer><nowait> x     <Plug>(TreeTerm)
  nmap <silent><buffer><nowait> n     <Plug>(TreeSearchAgain)
  nmap <silent><buffer><nowait> du    <Plug>(TreeCalcDirSize)
  nmap <silent><buffer><nowait> dU    <Plug>(TreeCalcAllDirSizes)
  xmap <silent><buffer><nowait> du    <Plug>(TreeCalcDirSize)
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


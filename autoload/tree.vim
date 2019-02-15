scriptencoding utf-8

let s:default_cmd = 'tree -c -F --dirsfirst --noreport'
let s:regex_name = ' \zs[^`|-│─├└  ]'

function! tree#Tree(options) abort
  let s:last_options = a:options
  let cmd = s:default_cmd.' '.a:options.' '.getcwd()
  if !&hidden && &modified
    echohl WarningMsg | echo 'There are unsaved changes.' | echohl NONE
    return
  endif
  enew
  let &l:statusline = ' '.cmd
  execute 'silent %!'.cmd
  if v:shell_error || !isdirectory(getline('1'))
    redraw!
    echohl WarningMsg | echo 'Press any button to close this buffer' | echohl NONE
    call getchar()
    bwipeout!
    redraw | echo
    return
  endif
  silent! %substitute/ / /g
  2
  setlocal nomodified buftype=nofile bufhidden=wipe nowrap nonumber foldcolumn=0
  call s:set_mappings()
  augroup tree
    autocmd!
    autocmd CursorMoved <buffer> call s:on_cursormoved()
    if exists('##DirChanged')
      autocmd DirChanged <buffer> call tree#Tree(s:last_options)
    endif
  augroup END
  echo '(q)uit l(c)d (e)dit (s)plit (v)split (t)abedit help(?)'
  highlight default link TreeDirectory Directory
  set filetype=tree
  syntax match TreeDirectory /[^│─├└  ]*\ze\/$/
endfunction

function! s:set_mappings() abort
  nnoremap <silent><buffer><nowait> ? :call tree#Help()<cr>
  nnoremap <silent><buffer><nowait> q :bwipeout \| echo<cr>
  nnoremap <silent><buffer><nowait> c :execute 'lcd'     tree#GetPath()<cr>
  nnoremap <silent><buffer><nowait> e :execute 'edit'    tree#GetPath()<cr>
  nnoremap <silent><buffer><nowait> s :execute 'split'   tree#GetPath()<cr>
  nnoremap <silent><buffer><nowait> v :execute 'vsplit'  tree#GetPath()<cr>
  nnoremap <silent><buffer><nowait> t :execute 'tabedit' tree#GetPath()<cr>
  nnoremap <silent><buffer><nowait> h :call tree#go_back()<cr>
  nnoremap <silent><buffer><nowait> l :call tree#go_forth()<cr>
  nnoremap <silent><buffer><nowait> K :call tree#go_up()<cr>
  nnoremap <silent><buffer><nowait> J :call tree#go_down()<cr>
endfunction

function! tree#go_up() abort
  let [line, col] = [line('.')-1, virtcol('.')-1]
  while line > 1
    let c = strwidth(matchstr(getline(line), '.\{-}\ze'.s:regex_name))
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
    let c = strwidth(matchstr(getline(line), '.\{-}\ze'.s:regex_name)) if c == col
      execute line
      return 1
    endif
    let line += 1
  endwhile
endfunction

function! tree#go_back() abort
  let [line, col] = [line('.')-1, virtcol('.')-1]
  while line > 1
    let c = strwidth(matchstr(getline(line), '.\{-}\ze'.s:regex_name))
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
    let c = strwidth(matchstr(getline(line), '.\{-}\ze'.s:regex_name))
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
    let c = match(getline(line), s:regex_name)
    if c < col
      let part = matchstr(getline(line)[c:], '.*')
      " handle symlinks
      let part = substitute(part, ' ->.*', '', '')
      let path = part . path
      let col = c
    endif
    let line -= 1
  endwhile
  return path
endfunction

function! s:on_cursormoved() abort
  normal! 0
  if line('.') <= 1 | 2 | endif
  call search(s:regex_name, '', line('.'))
endfunction

function! tree#Help() abort
  echo ' ?   this help'
  echo ' q   wipeout tree buffer'
  echo ' l   go to directory'
  echo ' h   go back one directory'
  echo ' K   go up to next entry of the same level'
  echo ' J   go down to next entry of the same level'
  echo ' c   :lcd into current entry and rerun :Tree with the same options'
  echo ' e   :edit current entry'
  echo ' s   :split current entry'
  echo ' v   :vsplit current entry'
  echo ' t   :tabedit current entry'
endfunction

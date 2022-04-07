scriptencoding utf-8
let s:default_cmd = has('win32') ? 'tree.exe' : 'tree'
let s:default_options = '-n -F --dirsfirst --noreport'
let s:entry_start_regex = '[^ │─├└`|-]'
let s:entry_start_regex = '^[│─├└ ␣]\+\(\[\s*[0-9]\+\(\.[0-9]\+\)\?[KMGTPE]\?\]\)\?\s\+'
let s:entry_start_regex_fold = '^\([ │─├└`|-]\{4}\)\+'
let s:prefix_and_path =  '^\([│─├└ ␣]\+\)'
let s:prefix_and_path .= '\(\[\s*[0-9]\+\%(\.[0-9]\+\)\?[KMGTPE]\?\]\)\?'
let s:prefix_and_path .= '\s\+\(.*\)'
let s:prefix_and_path_cache = {}
let s:path_cache = {}

if !exists('g:tree_remember_fold_state')
  let g:tree_remember_fold_state = 1
endif

" prepare logging with https://github.com/hupfdule/log.vim (if available)
silent! let s:log = log#getLogger(expand('<sfile>:t'))


function! tree#Tree(options) abort
  let s:last_options = a:options
  let cmd = printf('%s %s %s %s',
        \ s:default_cmd, s:default_options, a:options, shellescape(getcwd()))
  if !&hidden && &modified
    echohl WarningMsg | echo 'There are unsaved changes.' | echohl NONE
    return
  endif
  enew
  let &l:statusline = ' '.cmd
  execute 'silent %!'.cmd
  if v:shell_error || getline(1) =~# '\V [error opening dir]'
    redraw!
    echohl WarningMsg | echo 'Press any button to close this buffer' | echohl NONE
    call getchar()
    bwipeout!
    redraw | echo
    return
  endif
  silent! %substitute/ / /g
  2
  if exists("s:saved_pos")
    call setpos('.', s:saved_pos)
    unlet s:saved_pos
  endif
  setlocal nomodified buftype=nofile bufhidden=wipe nowrap nonumber foldcolumn=0 foldtext=foldtext#foldtext()
  call s:set_mappings()
  call foldtext#set_fold_mappings()
  augroup tree
    autocmd!
    autocmd CursorMoved <buffer> call s:on_cursormoved()
    if exists('##DirChanged')
      autocmd DirChanged <buffer> call tree#Tree(s:last_options)
    endif
  augroup END
  set foldexpr=tree#get_foldlevel(v:lnum)
  echo '(q)uit l(c)d (e)dit (s)plit (v)split (t)abedit help(?)'
  highlight default link TreeDirectory Directory
  highlight default link TreeSize      SpecialKey
  highlight default link TreeBars      NonText
  set filetype=tree
  syntax match  TreeDirectory /[^│─├└]*\/$/
  syntax region TreeSize      start=/[│─├└ ␣]*\zs\[/ end=/\]/ containedin=ALL
  syntax region TreeBars      start=/^/              end=/\ze[^│─├└␣ ]/

  let s:prefix_and_path_cache = {}
  let s:path_cache = {}

  if exists('s:scroll_to_path') && s:scroll_to_path !=# ''
    let scroll_to = s:search_path(s:scroll_to_path, s:scroll_to_path)
    call cursor(scroll_to, 1)
    normal! zv
    unlet s:scroll_to_path
  endif
endfunction

function! s:set_mappings() abort
  nnoremap <silent><buffer><nowait> ? :call tree#Help()<cr>
  nnoremap <silent><buffer><nowait> q :bwipeout \| echo<cr>
  nnoremap <silent><buffer><nowait> c :call tree#cd_to()<cr>
  nnoremap <silent><buffer><nowait> H :call tree#cd_up()<cr>
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

function! tree#go_up() abort
  let [line, col] = [line('.')-1, virtcol('.')-1]
  while line > 1
    let c = strwidth(matchstr(getline(line), s:entry_start_regex))
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
    let c = strwidth(matchstr(getline(line), s:entry_start_regex))
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
    let c = strwidth(matchstr(getline(line), s:entry_start_regex))
    if c < col
      execute line
      silent! normal! zc
      return 1
    endif
    let line -= 1
  endwhile
endfunction

function! tree#go_forth() abort
  let [line, col] = [line('.')+1, virtcol('.')-1]
  let last_line = line('$')
  while line <= last_line
    let c = strwidth(matchstr(getline(line), s:entry_start_regex))
    if c < col
      " cursor is on empty directory
      break
    endif
    if c > col
      execute line
      silent! normal! zo
      return 1
    endif
    let line += 1
  endwhile
endfunction

function! tree#get_prefix_and_path(lnum, only_dirs) abort
  let line = getline(a:lnum)
  if a:only_dirs && line[-1:] != '/'
    return []
  endif

  if has_key(s:prefix_and_path_cache, a:lnum)
    return s:prefix_and_path_cache[a:lnum]
  endif

  let match = matchlist(line, s:prefix_and_path)
  if match ==# []
    return []
  endif

  " now normalize the path
  let path = match[3]

  " 1. Handle symlinks.
  let path = substitute(path, ' ->.*', '', '')

  " 2. With `tree -Q`, every part is always surrounded by double quotes.
  if match(s:last_options, '-Q') >= 0
    let path = path =~ '/$'
          \ ? strpart(path, 1, strchars(path) - 3).'/'
          \ : strpart(path, 1, strchars(path) - 2)
    let path = substitute(path, '\"', '"', 'g')
    " By now we have normalized `part` as if -Q was never used.
  endif

  " 3. Handle double quotes in file names
  let path = escape(path, '"')

  let match[3] = path

  let s:prefix_and_path_cache[a:lnum] = match
  return match
endfunction

function! tree#GetPath() abort
  return tree#GetPathAt(line('.'))
endfunction

function! tree#GetPathAt(lnum) abort
  if has_key(s:path_cache, a:lnum)
    return s:path_cache[a:lnum]
  endif

  let prefix_and_path = tree#get_prefix_and_path(a:lnum, v:false)
  if prefix_and_path ==# []
    return ''
  endif

  let depth = strchars(prefix_and_path[1])
  let path  = prefix_and_path[3]

  let line = a:lnum - 1
  while line > 1 && depth > 4 " depth == 4 is a toplevel dir
    " FIXME: This is a bottleneck. On large trees this method is called
    " over and over again. Could we reduce that by using a recursive method
    " here?
    let prefix_and_path = tree#get_prefix_and_path(line, v:true)
    let line -= 1

    if prefix_and_path ==# []
      continue
    endif

    if strchars(prefix_and_path[1]) >= depth
      continue
    endif

    let path = prefix_and_path[3] . path
    let depth = strchars(prefix_and_path[1])
  endwhile

  let s:path_cache[a:lnum] = path
  return path
endfunction

function! tree#reload() abort
  let s:saved_pos = getcurpos()
  let s:saved_entry = tree#GetPath()
  let winline = winline()

  if g:tree_remember_fold_state
    echohl MoreMsg | echo "Remembering all folds for later restore (avoid by setting g:tree_remember_fold_state = 0)" | echohl None
    let start=reltime()
    call tree#save_folds()
    let save_duration = reltimestr(reltime(start))
    silent! call s:log.debug('tree#reload(): Saving folds took: ' . save_duration . ' seconds.')
  endif

  let start=reltime()
  call tree#Tree(s:last_options)
  let tree_duration = reltimestr(reltime(start))
  silent! call s:log.debug('tree#reload(): Rebuilding tree took: ' . tree_duration . ' seconds.')

  if g:tree_remember_fold_state
    echohl MoreMsg | echo "Restoring all folds" | echohl None
    normal! zR
    let start=reltime()
    call tree#restore_folds()
    let restore_duration = reltimestr(reltime(start))
    silent! call s:log.debug('tree#reload(): Restoring folds took: ' . restore_duration . ' seconds.')
  endif

  " Restore scroll position in case it has changed after reload
  let winline2 = winline()
  let scrolldiff = winline - winline2
  if scrolldiff > 0
    execute "normal! ".scrolldiff."\<C-Y>"
  elseif scrolldiff < 0
    execute "normal! ".abs(scrolldiff)."\<C-E>"
  endif
endfunction

function! s:on_cursormoved() abort
  normal! 0
  if line('.') <= 1 && line('$') > 1 | 2 | endif
  let ln= search(s:entry_start_regex.'\zs', '', line('.'))
  if virtcol('.') >= winwidth(0) / 2
    execute 'normal! zs'.(winwidth(0)/4).'zh'
  else
    normal! ze
  endif
endfunction

function! tree#save_folds() abort
  let save_pos = getcurpos()
  let s:saved_folds = []
  for lnum in range(1, line('$'))
    execute 'normal! ' . lnum . 'G'
    " TODO: Only visit directories?
    let foldstart = foldclosed(lnum)
    if foldstart ==# -1
      silent! call s:log.trace('tree#save_folds(): Line ' . lnum . ' is ignored, since it is not in a fold.')
      continue
    endif

    if foldlevel(lnum) == 0
      silent! call s:log.trace('tree#save_folds(): Line ' . lnum . ' is ignored, since it has foldlevel 0.')
      continue
    endif

    if getline(lnum-1)[-1:] !=# '/'
      silent! call s:log.trace('tree#save_folds(): Line ' . lnum . ' is ignored, since it is not a directory.')
      continue
    endif

    let foldend   = foldclosedend(lnum)
    let entry = {}
    let entry['lnum']      = lnum
    let entry['path']      = tree#GetPath()
    "let entry['path']      = getline('.')
    let entry['filename']  = matchstr(getline('.'), s:entry_start_regex . '\zs.*')
    let entry['foldlevel'] = foldlevel(lnum)
    let entry['folded']    = foldstart != -1
    call add(s:saved_folds, entry)

    if foldstart != -1
      normal! zo
    endif
  endfor

  call reverse(s:saved_folds)

  if exists('s:log')
    let log_saved_folds = ''
    for sf in s:saved_folds
      let log_saved_folds .= '  ' . string(sf) . "\n"
    endfor
    silent! call s:log.debug("tree#save_folds(): Saved folds: \n" . log_saved_folds)
  endif

  call setpos('.', save_pos)
endfunction

function! tree#restore_folds() abort
  if !exists('s:saved_folds')
    silent! call s:log.trace('tree#restore_folds(): Not restoring anything since no folds are saved')
    return
  endif

  call foldtext#unset_fold_mappings()
  let save_pos = getcurpos()
  normal! G
  for entry in s:saved_folds
    let lnum = s:search_path(entry['filename'], entry['path'])
    " skip this entry if it doesn't exist anymore
    if lnum ==# -1
      silent! call s:log.trace('tree#restore_folds(): Line ' . lnum . ' with path ' . entry['path'] . " doesn't exist anymore.")
      continue
    endif

    " skip this entry if it is not folded (and therefore cannot be opened or closed)
    if entry['foldlevel'] == 0
      silent! call s:log.trace('tree#restore_folds(): Line ' . lnum . ' with path ' . entry['path'] . ' has foldlevel 0. Ignoring it.')
      continue
    endif

    execute 'normal! ' . lnum . 'G'
    " FIXME: Only apply folding operation if the current state isn't yet
    "        correct?
    "        Especially on closing it would be possible to close the wrong
    "        fold otherwise.
    "        Alternatively open everything before and only close what has
    "        to be closed.
    if entry['folded'] == 0
      silent! call s:log.trace('tree#restore_folds(): Line ' . lnum . ' with path ' . entry['path'] . ' is open.')
      normal! zo
    else
      silent! call s:log.trace('tree#restore_folds(): Line ' . lnum . ' with path ' . entry['path'] . ' is closed.')
      normal zc
    endif
  endfor
  unlet s:saved_folds
  call setpos('.', save_pos)
  call foldtext#set_fold_mappings()
endfunction

function! s:search_path(filename, full_path) abort
  " https://stackoverflow.com/a/11311701/572645
  let escaped_filename = '\V' . escape(a:filename, '/\%')
  let startline = line('.')
  let lnum = search(s:entry_start_regex . '\zs' . escaped_filename, 'bcw')
  if tree#GetPath() ==# a:full_path
    return lnum
  endif

  " if this is not yet the correct path, search until we find it
  let first_match= lnum
  while v:true
    let startline = line('.')
    let lnum = search(s:entry_start_regex . '\zs' . escaped_filename, 'bw')
    " abort if we found the first match again
    if lnum ==# first_match
      return -1
    endif

    " end the search if we found the correct path
    if tree#GetPath() ==# a:full_path
      return lnum
    endif
  endwhile
endfunction

function! tree#get_foldlevel(lnum) abort
  let line = getline(a:lnum)
  return (strwidth(matchstr(line, s:entry_start_regex_fold)) / 4)
endfunction

function! tree#open_term() abort
  split
  execute 'lcd' tree#GetPath()
  if has('nvim')
    terminal
  else
    terminal ++curwin
  endif
endfunction

function! tree#cd_to() abort
  let path = tree#GetPath()
  if path !=# ''
    :execute 'lcd' path
  endif
endfunction

function! tree#cd_up() abort
  let s:scroll_to_path = fnamemodify(getcwd(), ':t') . '/'
  lcd ..
endfunction

function! tree#Help() abort
  echo ' ?   this help'
  echo ' q   wipeout tree buffer'
  echo ' l   go to directory'
  echo ' h   go back one directory'
  echo ' K   go up to next entry of the same level'
  echo ' J   go down to next entry of the same level'
  echo ' r   reload tree with the same options'
  echo ' c   :lcd into current entry and rerun :Tree with the same options'
  echo ' H   :lcd into the parent directory and rerun :Tree with the same options'
  echo ' e   :edit current entry'
  echo ' p   :edit current entry in previous (last accessed) window'
  echo ' s   :split current entry'
  echo ' v   :vsplit current entry'
  echo ' t   :tabedit current entry'
  echo ' x   :terminal on current entry'
endfunction

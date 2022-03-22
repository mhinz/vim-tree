scriptencoding utf-8

let s:default_cmd = has('win32') ? 'tree.exe' : 'tree'
let s:default_options = '-n -F --dirsfirst --noreport'
let s:entry_start_regex = '[^ │─├└`|-]'
let s:entry_start_regex = '^[│─├└ ␣]\+\(\[\s*[0-9]\+\(\.[0-9]\+\)\?[KMGTPE]\?\]\)\?\s\+'

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
  setlocal nomodified buftype=nofile bufhidden=wipe nowrap nonumber foldcolumn=0
  call s:set_mappings()
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
  set filetype=tree
  syntax match TreeDirectory /[^│─├└  ]*\ze\/$/
  syntax match TreeSize      /^[│─├└ ␣]\+\zs\[\s*[0-9]\+\(\.[0-9]\+\)\?[KMGTPE]\?\]\ze\s\+\S/
endfunction

function! s:set_mappings() abort
  nnoremap <silent><buffer><nowait> ? :call tree#Help()<cr>
  nnoremap <silent><buffer><nowait> q :bwipeout \| echo<cr>
  nnoremap <silent><buffer><nowait> c :execute 'lcd'              tree#GetPath()<cr>
  nnoremap <silent><buffer><nowait> H :lcd ..<cr>
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

function! tree#GetPath() abort
  let path = ''
  let [line, col] = [line('.'), col('.')]
  while line > 1
    let c = match(getline(line), s:entry_start_regex.'\zs')
    if c < col
      let part = matchstr(getline(line)[c:], '.*')
      " Handle symlinks.
      let part = substitute(part, ' ->.*', '', '')
      " With `tree -Q`, every part is always surrounded by double quotes.
      if match(s:last_options, '-Q') >= 0
        let part = part =~ '/$'
              \ ? strpart(part, 1, strchars(part) - 3).'/'
              \ : strpart(part, 1, strchars(part) - 2)
        let part = substitute(part, '\"', '"', 'g')
        " By now we have normalized `part` as if -Q was never used.
      endif
      let path = escape(part, '"') . path
      let col = c
    endif
    let line -= 1
  endwhile
  return path
endfunction

function! tree#reload() abort
  let s:saved_pos = getcurpos()
  let s:saved_entry = tree#GetPath()
  call tree#save_folds()
  call tree#Tree(s:last_options)
  normal! zR
  call tree#restore_folds()
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
      continue
    endif

    if foldlevel(lnum) == 0
      continue
    endif

    if getline(lnum-1)[-1:] !=# '/'
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

  call setpos('.', save_pos)
endfunction

function! tree#restore_folds() abort
  if !exists('s:saved_folds')
    return
  endif

  let save_pos = getcurpos()
  normal! G
  for entry in s:saved_folds
    let lnum = s:search_path(entry['filename'], entry['path'])
    " skip this entry if it doesn't exist anymore
    if lnum ==# -1
      continue
    endif

    " skip this entry if it is not folded (and therefore cannot be opened or closed)
    if entry['foldlevel'] == 0
      continue
    endif

    if entry['folded'] == 0
      normal! zo
    else
      normal zc
    endif
  endfor
  unlet s:saved_folds
  call setpos('.', save_pos)
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

function! tree#get_foldlevel(lnum)
  let line = getline(a:lnum)
  return line =~ '/$'
        \ ? '>'.(strwidth(matchstr(line, s:entry_start_regex)) / 4)
        \ : '='
  endif
endfunction

function! tree#open_term()
  split
  execute 'lcd' tree#GetPath()
  if has('nvim')
    terminal
  else
    terminal ++curwin
  endif
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

" courtesy of https://github.com/jrudess/vim-foldtext/blob/master/plugin/foldtext.vim
if has('multi_byte')
    let defaults = {'placeholder': '⋯',   'line': '▤', 'multiplication': '×' }
else
    let defaults = {'placeholder': '...', 'line': 'L', 'multiplication': '*' }
endif

let g:vimtree_foldtext_placeholder    = get(g:, 'vimtree_foldtext_placeholder',    defaults['placeholder'])
let g:vimtree_foldtext_line           = get(g:, 'vimtree_foldtext_line',           defaults['line'])
let g:vimtree_foldtext_multiplication = get(g:, 'vimtree_foldtext_multiplication', defaults['multiplication'])
let g:vimtree_foldtext_info           = get(g:, 'vimtree_foldtext_info',           1)
let g:vimtree_foldtext_width          = get(g:, 'vimtree_foldtext_width',          0)

unlet defaults

function! foldtext#foldtext()
    let fs = v:foldstart
    while getline(fs) =~ '^\s*$'
        let fs = nextnonblank(fs + 1)
    endwhile
    if fs > v:foldend
        let line = getline(v:foldstart)
    else
        let spaces = repeat(' ', &tabstop)
        let line = substitute(getline(fs), '\t', spaces, 'g')
    endif

    let endBlockChars   = ['end', '}', ']', ')', '})', '},', '}}}']
    let endBlockRegex = printf('^\(\s*\|\s*\"\s*\)\(%s\);\?$', join(endBlockChars, '\|'))
    let endCommentRegex = '\s*\*/\s*$'
    let startCommentBlankRegex = '\v^\s*/\*!?\s*$'

    let foldEnding = strpart(getline(v:foldend), indent(v:foldend), 3)

    if foldEnding =~ endBlockRegex
        if foldEnding =~ '^\s*\"'
            let foldEnding = strpart(getline(v:foldend), indent(v:foldend)+2, 3)
        end
        let foldEnding = " " . g:vimtree_foldtext_placeholder . " " . foldEnding
    elseif foldEnding =~ endCommentRegex
        if getline(v:foldstart) =~ startCommentBlankRegex
            let nextLine = substitute(getline(v:foldstart + 1), '\v\s*\*', '', '')
            let line = line . nextLine
        endif
        let foldEnding = " " . g:vimtree_foldtext_placeholder . " " . foldEnding
    else
        let foldEnding = " " . g:vimtree_foldtext_placeholder
    endif
    let foldEnding = substitute(foldEnding, '\s\+$', '', '')

    redir =>signs | exe "silent sign place buffer=".bufnr('') | redir end
    let signlist = split(signs, '\n')
    let foldColumnWidth = (&foldcolumn ? &foldcolumn : 0)
    let numberColumnWidth = &number ? strwidth(line('$')) : 0
    let signColumnWidth = len(signlist) >= 2 ? 2 : 0
    let width = winwidth(0) - foldColumnWidth - numberColumnWidth - signColumnWidth

    let ending = ""
    if g:vimtree_foldtext_info
        if g:vimtree_foldtext_width > 0 && g:vimtree_foldtext_width < (width-6)
            let endsize = "%-" . string(width - g:vimtree_foldtext_width + 4) . "s"
        else
            let endsize = "%-11s"
        end
        let foldSize = 1 + v:foldend - v:foldstart
        let ending = printf("%s%s%s", g:vimtree_foldtext_line, g:vimtree_foldtext_multiplication, foldSize)
        let ending = printf(endsize, ending)

        if strwidth(line . foldEnding . ending) >= width
            let line = strpart(line, 0, width - strwidth(foldEnding . ending) - 2)
        endif
    endif

    let expansionStr = repeat(" ", width - strwidth(line . foldEnding . ending))
    return line . foldEnding . expansionStr . ending
endfunction

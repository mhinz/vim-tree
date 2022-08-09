if exists("b:current_syntax")
  finish
endif

highlight default link TreeDirectory Directory
highlight default link TreeSize      SpecialKey
highlight default link TreeBars      NonText

syntax match  TreeDirectory /[^│─├└]*\/$/
syntax region TreeSize      start=/[│─├└ ␣]*\zs\[/ end=/\]/ containedin=ALL
syntax region TreeBars      start=/^/              end=/\ze[^│─├└␣ ]/

let b:current_syntax = "tree"

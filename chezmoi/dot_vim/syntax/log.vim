" Vim syntax file
" Language:         Log files
" Maintainer:       Jim Lawton <jim.lawton@gmail.com>
" Latest Revision:  2008-08-13

if exists("b:current_syntax")
  finish
endif

let s:cpo_save = &cpo
set cpo&vim

syntax region  msgFatal      start="[ ]*FATAL" end="$"
syntax region  msgError      start="[ ]*ERROR" end="$"
syntax region  msgError2     start=".*_ERR_.*" end="$"
syntax region  msgWarn       start="[ ]*WARN"  end="$"
syntax region  msgEntry      start='[ ]*==>'   end="$"
syntax region  msgExit       start='[ ]*<=='   end="$"

hi def link msgFatal    ErrorMsg
hi def link msgError    ErrorMsg
hi def link msgWarn     Special
hi def link msgEntry    Identifier
hi def link msgExit     Identifier
hi def link msgError2   ErrorMsg

let b:current_syntax = "messages"

let &cpo = s:cpo_save
unlet s:cpo_save


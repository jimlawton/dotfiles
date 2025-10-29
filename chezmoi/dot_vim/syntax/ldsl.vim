" Vim syntax file
" Language:         LDSL files
" Maintainer:       David O'Shea <david.oshea@s3group.com>
" Latest Revision:  2009-02-05

if exists("b:current_syntax")
  finish
endif

let s:cpo_save = &cpo
set cpo&vim

syn region  string      contained display start=+"+ end=+"+ skip=+\\"+
syn match   comment     display '//.*$'

syn match   keyword     display '\(^\|\s\+\)\zs\(global\|reference\|version\|prefix\|sync\|retvar\|include\|trace\|entry\|error\|warn\|info\|exit\|class\|description\|device\|instances\|type\|states\|events\|function\|ioctl\|deprecated\|state\|parameter\|goto\|adaptation\)\(\s\+\|$\)[^;{]*' contains=device,fn,ioctl,description,instances,reference,version,prefix,retvar,include,trace,sync,deprecated,devtype,class,state,parameter,goto,adaptation,events
syn match   adaptation  contained display 'adaptation\s\+\zs\(yes\|no\)\ze;'
syn match   goto        contained display 'goto\s\+\zs[^ ;}]*\ze;' contains=identifier
syn match   parameter   contained display 'parameter\s\+\zs.*' contains=string,comment
syn match   state       contained display 'state\s\+\zs[^ ;{]*\(\s\+->\s\+[^ ;{]*\)\?\ze;' contains=statename
syn match   statename   contained display '[^ ;~>-]*'
syn match   device      contained display 'device\s\+[^ ;{]* *' contains=identifier
syn match   class       contained display 'class\s\+[^ ;{]* *' contains=identifier
syn match   fn          contained display 'function\s\+\zs[^ ;{]*' contains=fnname,error
syn match   ioctl       contained display 'ioctl\s\+[^ ;]*' contains=identifier
syn match   description contained display 'description\s\+\zs.*' contains=string,comment
syn match   reference   contained display 'reference\s\+\zs.*' contains=string,comment
syn match   version     contained display 'version\s\+\zs.*' contains=string,comment
syn match   prefix      contained display 'prefix\s\+\zs.*' contains=string,comment
syn match   retvar      contained display 'retvar\s\+\zs.*' contains=string,comment
syn match   devtype     contained display 'type\s\+\zs.*\ze;' contains=devtypet
syn match   devtypet    contained display 'multiple\|singleton\|unnumbered'
syn match   include     contained display 'include\s\+\zs\([<"][^>"]*[>"]\|none\)\ze;' contains=string,comment
syn match   trace       contained display '\(entry\|error\|warn\|info\|exit\)\s\+\zs.*' contains=string,comment
syn match   instances   contained display 'instances\s\+\zs[0-9]*'
syn match   fnname      contained display '\(init\(iali[sz]e\)\?\|term\(inate\)\?\|open\|close\|read\|write\|poll\|select\|lseek\|mmap\|munmap\|msync\)\ze[ ;]'
syn match   sync        contained display 'sync\s\+\zs[^;]*' contains=synctype,comment
syn match   synctype    contained display '\(none\|sema\|mutex\)\ze;'
syn match   deprecated  contained display 'deprecated\s\+\zs[^;{]*' contains=ioctl,fn,device,class
syn match   identifier  contained display '\s\+\zs[^ ;]*'
syn match   error       contained display '\s\+\zs[^ ;]*'

hi     link device    Statement
hi     link adaptation Identifier
hi     link goto      Identifier
hi     link state     Statement
hi     link statename Identifier
hi     link class     Statement
hi     link fn        Error
hi     link function  Statement
hi def link fnname    Identifier
hi     link ioctl     Statement
hi def link instances Number
hi def link sync      Error
hi def link devtype   Error
hi def link devtypet  Identifier
hi def link synctype  Identifier
hi def link deprecated Error
hi def link error     Error

let b:current_syntax = "ldsl"

let &cpo = s:cpo_save
unlet s:cpo_save

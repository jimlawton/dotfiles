" ########################################################################
" # VI text editor setup
" ########################################################################

" NOTE: make sure vim is actually installed, and that you're not trying 
" to run this in vi!

set shell=/bin/bash 
set term=linux

" set paste
" set number

" set our tabs to four spaces
set ts=4
" set smartindent
set tabstop=4
set shiftwidth=4
set expandtab

" turn syntax highlighting on by default
syntax on
filetype plugin indent on

" set auto-indenting on for programming
set ai

" turn off compatibility with the old vi
set nocompatible

" turn on the "visual bell" - which is much quieter than the "audio blink"
set visualbell 
set t_vb=

" disable screen restoring
set t_ti= t_te=

" automatically show matching brackets. works like it does in bbedit.
set showmatch

" make that backspace key work the way it should
" set backspace=indent,eol,start
set backspace=indent,eol

set expandtab shiftwidth=4 tabstop=4

filetype off                   " required!

" use `:W` to sudo save a file if you forget to `sudo vim` the file
command W w !sudo tee % > /dev/null

filetype plugin indent on     " required!

"let g:syntastic_enable_signs=1
"let g:syntastic_auto_jump=1
"let g:syntastic_stl_format = '[%E{Err: %fe #%e}%B{, }%W{Warn: %fw #%w}]'

"set statusline+=%#warningmsg#
"set statusline+=%{SyntasticStatuslineFlag()}
"set statusline+=%*

" Syntax highlighting only when vim-common is there
if has("mouse_gpm") && filereadable("/usr/share/vim/syntax/syntax.vim")
  syntax on filetype on
endif

set background=dark
colorscheme solarized

"Display a status-line
set statusline=~

"I know it's horrible for a vi master but useful for newbies.
imap <C-a> <Esc>I
imap <C-e> <ESC>A
map <C-Tab> <C-W>w
imap <C-Tab> <C-O><C-W>w
cmap <C-Tab> <C-C><C-Tab>

"Some macros to manage the buffer of vim
map <F5> :bp<C-M>
map <F6> :bn<C-M>
map <F7> :bd<C-M>

" set our tabs to four spaces
set ts=4

"Default backspace like normal
set bs=2

"Terminal for 80 char ? so vim can play till 79 char.
set textwidth=79

"Some option desactivate by default (remove the no).
set nobackup
set nohlsearch
set noincsearch

" Tell vim to remember certain things when we exit
"  '50  :  marks will be remembered for up to 50 previously edited files
"  "100 :  will save up to 100 lines for each register
"  :50 :  up to 50 lines of command-line history will be remembered
"  %    :  saves and restores the buffer list
"  n... :  where to save the viminfo files
set viminfo='50,\"100,:50,%,n~/.viminfo

"Show the position of the cursor.
set ruler

"" Gzip and Bzip2 files support
" Take from the Debian package and the exemple on $VIM/vim_exemples
if has("autocmd")

autocmd FileType agc setlocal shiftwidth=8 tabstop=8
"autocmd FileType agc setlocal tabstop=8

function! ResCur()
  if line("'\"") <= line("$")
    normal! g`"
    return 1
  endif
endfunction

augroup resCur
  autocmd!
  autocmd BufWinEnter * call ResCur()
augroup END

au BufNewFile,BufRead *.log setf logs

" Set some sensible defaults for editing C-files
augroup cprog
  " Remove all cprog autocommands
  au!

  " When starting to edit a file:
  "   For *.c and *.h files set formatting of comments and set C-indenting on.
  "   For other files switch it off.
  "   Don't change the order, it's important that the line with * comes first.
  autocmd BufRead *       set formatoptions=tcql nocindent comments&
  autocmd BufRead *.c,*.h set expandtab shiftwidth=4 tabstop=4 formatoptions=croql cindent comments=sr:/*,mb:*,el:*/,://
augroup END

" Set some sensible defaults for editing Python files
augroup pyprog
  " Remove all pyprog autocommands
  au!

  " When starting to edit a file:
  "   For *.py set formatting of comments and set indenting on.
  "   Don't change the order, it's important that the line with * comes first.
  autocmd BufRead *.py set expandtab shiftwidth=4 tabstop=4
augroup END

" Also, support editing of gzip-compressed files. DO NOT REMOVE THIS!
" This is also used when loading the compressed helpfiles.
augroup gzip
  " Remove all gzip autocommands
  au!

  " Enable editing of gzipped files
  "	  read:	set binary mode before reading the file
  "		uncompress text in buffer after reading
  "	 write:	compress file after writing
  "	append:	uncompress file, append, compress file
  autocmd BufReadPre,FileReadPre	*.gz set bin
  autocmd BufReadPre,FileReadPre	*.gz let ch_save = &ch|set ch=2
  autocmd BufReadPost,FileReadPost	*.gz '[,']!gunzip
  autocmd BufReadPost,FileReadPost	*.gz set nobin
  autocmd BufReadPost,FileReadPost	*.gz let &ch = ch_save|unlet ch_save
  autocmd BufReadPost,FileReadPost	*.gz execute ":doautocmd BufReadPost " . %:r

  autocmd BufWritePost,FileWritePost	*.gz !mv <afile> <afile>:r
  autocmd BufWritePost,FileWritePost	*.gz !gzip <afile>:r

  autocmd FileAppendPre			*.gz !gunzip <afile>
  autocmd FileAppendPre			*.gz !mv <afile>:r <afile>
  autocmd FileAppendPost		*.gz !mv <afile> <afile>:r
  autocmd FileAppendPost		*.gz !gzip <afile>:r
augroup END

augroup bzip2
  " Remove all bzip2 autocommands
  au!

  " Enable editing of bzipped files
  "       read: set binary mode before reading the file
  "             uncompress text in buffer after reading
  "      write: compress file after writing
  "     append: uncompress file, append, compress file
  autocmd BufReadPre,FileReadPre        *.bz2 set bin
  autocmd BufReadPre,FileReadPre        *.bz2 let ch_save = &ch|set ch=2
  autocmd BufReadPost,FileReadPost      *.bz2 set cmdheight=2|'[,']!bunzip2
  autocmd BufReadPost,FileReadPost      *.bz2 set cmdheight=1 nobin|execute ":doautocmd BufReadPost " . %:r
  autocmd BufReadPost,FileReadPost      *.bz2 let &ch = ch_save|unlet ch_save

  autocmd BufWritePost,FileWritePost    *.bz2 !mv <afile> <afile>:r
  autocmd BufWritePost,FileWritePost    *.bz2 !bzip2 <afile>:r

  autocmd FileAppendPre                 *.bz2 !bunzip2 <afile>
  autocmd FileAppendPre                 *.bz2 !mv <afile>:r <afile>
  autocmd FileAppendPost                *.bz2 !mv <afile> <afile>:r
  autocmd FileAppendPost                *.bz2 !bzip2 -9 --repetitive-best <afile>:r

  autocmd FileType make setlocal noexpandtab
augroup END

autocmd FileType python set complete+=k/usr/local/pydiction isk+=.,(

endif " has ("autocmd")

" Use terminals bracketed paste mode to set/unset Vims paste mode when you paste.
" https://coderwall.com/p/if9mda/automatically-set-paste-mode-in-vim-when-pasting-in-insert-mode
let &t_SI .= "\<Esc>[?2004h"
let &t_EI .= "\<Esc>[?2004l"

inoremap <special> <expr> <Esc>[200~ XTermPasteBegin()

function! XTermPasteBegin()
  set pastetoggle=<Esc>[201~
  set paste
  return ""
endfunction


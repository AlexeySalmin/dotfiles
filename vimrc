" 2016-12-20: created by salmin

runtime! debian.vim

syntax on
colo torte

set statusline=%F%m%r%h%w\ [%{&ff}]\ [%Y]\ [%LL]\ %=\ [0x\%02.2B]\ [%04l,%03v]\ [%02p%%]
set laststatus=2
set number

filetype plugin indent on

set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4

" Uncomment the following to have Vim jump to the last position when
" reopening a file
if has("autocmd")
  au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
endif

set showcmd         " Show (partial) command in status line.
set showmatch       " Show matching brackets.

" TODO replace with the DeleteTrailingWhitespace plugin
autocmd BufWritePre * :%s/\s\+$//e

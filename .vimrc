" $VIMRUNTIME refers to the versioned system directory where Vim stores its
" Last updated: 2023-04-11

runtime! debian.vim

syntax on

" If using a dark background within the editing area and syntax highlighting
" turn on this option as well
set background=dark

" Uncomment the following to have Vim jump to the last position when
" reopening a file
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

" Uncomment the following to have Vim load indentation rules and plugins
" according to the detected filetype.
filetype plugin indent on

" The following are commented out as they cause vim to behave a lot
" differently from regular Vi. They are highly recommended though.
set showcmd		" Show (partial) command in status line.
" My own vimrc options here
set number
set cursorline
set scrolloff=10
set incsearch
set ignorecase
set showmatch
set wildmenu
set wildmode=list:longest
set wildignore=*.jpg,*.png,*.gif,*.pdf,*.pyc,*.flv,*.img

"ffs use standard cut and paste
nnoremap <C-y> "+y
vnoremap <C-y> "+y
nnoremap <C-p> "+gP
vnoremap <C-p> "+gP

" Highlight all instances of the word under cursor with F4
nnoremap <F4> :match StatusLineTerm /<C-R><C-W>/<CR>

" Source a global configuration file if available
if filereadable("/etc/vim/vimrc.local")
  source /etc/vim/vimrc.local
endif

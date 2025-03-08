" ~/.vimrc
" Vim/Neovim configuration file
" Last updated: 2025-03-08

" Basic settings
" --------------
syntax on                " Enable syntax highlighting
set number               " Show line numbers
set relativenumber       " Show relative line numbers
set cursorline           " Highlight the current line
set scrolloff=10         " Keep 10 lines visible above/below cursor
set incsearch            " Highlight matches as you type
set ignorecase           " Ignore case when searching
set smartcase            " Override ignorecase if search contains uppercase
set showmatch            " Highlight matching brackets
set wildmenu             " Enhanced command-line completion
set wildmode=list:longest " Complete longest common string, then list alternatives
set wildignore=*.jpg,*.png,*.gif,*.pdf,*.pyc,*.flv,*.img  " Ignore these files in completion

" Avoid mistyping
cnoreabbrev W w
cnoreabbrev Q q
cnoreabbrev Wq wq
cnoreabbrev WQ wq

" Clipboard integration
" --------------------
" Use system clipboard for yank and paste operations
if has('clipboard')
  nnoremap <C-y> "+y
  vnoremap <C-y> "+y
  nnoremap <C-p> "+gP
  vnoremap <C-p> "+gP
endif

" Highlight all instances of the word under cursor with F4
nnoremap <F4> :match StatusLineTerm /<C-R><C-W>/<CR>

" Neovim-specific settings
" -----------------------
if has('nvim')
  " Enable mouse support in all modes
  set mouse=a
  
  " Enable true color support if terminal supports it
  if exists('+termguicolors')
    set termguicolors
  endif
  
  " Terminal settings
  autocmd TermOpen * setlocal nonumber norelativenumber
  
  " Easy terminal navigation
  tnoremap <Esc> <C-\><C-n>
  tnoremap <C-h> <C-\><C-n><C-w>h
  tnoremap <C-j> <C-\><C-n><C-w>j
  tnoremap <C-k> <C-\><C-n><C-w>k
  tnoremap <C-l> <C-\><C-n><C-w>l
endif

" Window navigation
" ----------------
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Restore cursor position
" ----------------------
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

" File type detection
" ------------------
filetype plugin indent on
set expandtab            " Use spaces instead of tabs
set tabstop=4            " Tab width is 4 spaces
set shiftwidth=4         " Indent with 4 spaces
set softtabstop=4        " 4 spaces in tab when editing

" File type specific indentation
augroup FileTypeIndent
  autocmd!
  autocmd FileType yaml setlocal tabstop=2 shiftwidth=2 softtabstop=2
  autocmd FileType json setlocal tabstop=2 shiftwidth=2 softtabstop=2
  autocmd FileType javascript setlocal tabstop=2 shiftwidth=2 softtabstop=2
  autocmd FileType html setlocal tabstop=2 shiftwidth=2 softtabstop=2
  autocmd FileType css setlocal tabstop=2 shiftwidth=2 softtabstop=2
  autocmd FileType dockerfile setlocal tabstop=2 shiftwidth=2 softtabstop=2
  autocmd FileType sh setlocal tabstop=2 shiftwidth=2 softtabstop=2
augroup END

" Source a global configuration file if available
if filereadable("/etc/vim/vimrc.local")
  source /etc/vim/vimrc.local
endif

"// GENERAL SETTINGS
set number
set hlsearch
set smartindent
set laststatus=2
set wildmenu
set ruler
set history=1000
set encoding=utf8
set clipboard+=unnamedplus
syntax enable

" Esc SETTINGS
inoremap jk <Esc>
inoremap jj <Esc>

set rtp+=~/.vim/bundle/Vundle.vim
set rtp+=~/.vim/bundle/neoterm
" PLUGIN SETTINGS
call plug#begin('~/.config/nvim/plugged')
Plug 'vim-airline/vim-airline'
Plug 'dense-analysis/ale' "// Linter
Plug 'airblade/vim-rooter'
Plug 'rizzatti/dash.vim'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'tpope/vim-commentary'
Plug 'preservim/nerdtree'
Plug 'ryanoasis/vim-devicons'
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'cocopon/iceberg.vim'
Plug 'tpope/vim-sensible'
"//Plug 'tpope/vim-fugitive'
call plug#end()

"//YouCompleteMe
"// ref: https://qiita.com/hanajori/items/75f9cc7c1294502ee19e
filetype plugin on
call vundle#begin()
   Plugin 'VundleVim/Vundle.vim'
   Plugin 'file:///Users/oreno/.vim/bundle/YouCompleteMe'
call vundle#end()


colorscheme iceberg

" NERDTree SETTINGS
nmap <C-f> :NERDTreeToggle<CR>
let g:airline#extensions#tabline#enabled = 1


" Airline SETTINGS
let g:airline_powerline_fonts = 1
nmap <C-p> <Plug>AirlineSelectPrevTab
nmap <C-n> <Plug>AirlineSelectNextTab



"//スニペット
let g:UltiSnipsExpandTrigger='<c-j>'
let g:UltiSnipsJumpForwardTrigger="<c-b>"
let g:UltiSnipsJumpBackwardTrigger="<c-z>"

"//入力補完
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
nmap <C-p> :History<CR>

"//定義元ジャンプ
set statusline^=%{coc#status()}
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <silent> gf <Plug>(coc-format)
nnoremap <silent> K :call <SID>show_documentation()<CR>

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

"\\ Formatter
"dense-analysis/ale
let g:ale_set_highlights = 0
let g:ale_linters = {'python': ['flake8']}
let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
let g:ale_fixers = {
  \   '*': ['remove_trailing_lines', 'trim_whitespace'],
  \   'python': ['black'],
  \ }
let g:ale_fix_on_save = 1

"Diagnostics
highlight CocErrorSign ctermfg=15 ctermbg=196
highlight CocWarningSign ctermfg=0 ctermbg=172


"// YouCompleteMe
let g:ycm_auto_triger=1
let g:ycm_min_num_of_chars_for_completion=1
let g:ycm_autoclose_preview_window_after_insertion=1


tnoremap <silent> <ESC> <C-\><C-n><C-w>
nnoremap <silent> <C-e> V:TREPLSendLine<cr>j^
vnoremap <silent> <C-e> V:TREPLSendSelection<cr>'>j^

"// ------------------ outdated ---------------------
" /// Enable Netrw (default file browser)
" filetype plugin on
" /// Netrw SETTINGS
" let g:netwr_banner = 0
" let g:netrw_liststyle = 3
" let g:netrw_browse_split = 4
" let g:netrw_winsize = 30
" let g:netrw_sizesyle = "H"
" let g:netrw_timefmt = "%Y/%m/%d(%a) %H:%M:%S"
" let g:netrw_preview = 1

"/// SPLIT BORDER SETTINGS
"//hi VertSplit cterm=nonet

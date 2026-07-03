" ~/.vimrc — sensible defaults, no external plugins required

" --- General ---
set nocompatible              " 使用 Vim 而非 vi 模式
filetype plugin indent on     " 依檔案類型載入縮排/外掛
syntax enable                 " 語法高亮
set encoding=utf-8
set hidden                    " 允許未存檔即切換 buffer
set autoread                  " 外部變動時自動重讀
set history=1000
set ttimeoutlen=10            " 縮短 Esc 後等待
set mouse=a                   " 啟用滑鼠
set updatetime=300

" --- UI ---
set number                    " 行號
set relativenumber            " 相對行號
set ruler
set showcmd                   " 顯示輸入中的指令
set wildmenu                  " 指令補全選單
set wildmode=longest:full,full
set laststatus=2              " 永遠顯示狀態列
" 狀態列：絕對路徑 + 修改/唯讀旗標 ……… 檔案類型 [目前行/總行數 : 欄] 百分比
set statusline=%{expand('%:p')}%m%r%h%w%=%y\ [%l/%L\ :\ %c]\ %p%%
set scrolloff=5               " 上下保留 5 行
set sidescrolloff=8
set display+=lastline
set lazyredraw
set splitright                " 新分割視窗在右/下
set splitbelow
if has('termguicolors')
  set termguicolors
endif

" --- Search ---
set ignorecase                " 搜尋忽略大小寫
set smartcase                 " 但有大寫時則區分
set incsearch                 " 即時搜尋
set hlsearch                  " 高亮結果
set gdefault                  " :s 預設全行取代

" --- Indentation ---
set autoindent
set smartindent
set expandtab                 " Tab 轉空白
set tabstop=4
set shiftwidth=4
set softtabstop=4
set shiftround
set backspace=indent,eol,start

" --- Wrapping & whitespace ---
" set nowrap
set linebreak
set list
set listchars=tab:▸\ ,trail:·,extends:>,precedes:<,nbsp:+

" --- Files / backup ---
set noswapfile
set nobackup
set nowritebackup
if has('persistent_undo')
  set undofile
  set undodir=~/.vim/undo//
  if !isdirectory($HOME . '/.vim/undo')
    call mkdir($HOME . '/.vim/undo', 'p', 0700)
  endif
endif

" --- Clipboard (若編譯有支援) ---
if has('clipboard')
  set clipboard=unnamedplus
endif

" --- Keymaps ---
let mapleader = " "
" 清除搜尋高亮
nnoremap <silent> <leader><space> :nohlsearch<CR>
" 快速存檔 / 離開
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
" 視窗間移動
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
" 在換行下也能直覺移動
nnoremap j gj
nnoremap k gk
" 保持視覺選取後再次縮排
vnoremap < <gv
vnoremap > >gv
" Y 行為與 D/C 一致（複製到行尾）
nnoremap Y y$

" --- 記住上次游標位置 ---
autocmd BufReadPost *
  \ if line("'\"") > 1 && line("'\"") <= line("$") |
  \   exe "normal! g`\"" |
  \ endif

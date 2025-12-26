vnoremap <C-c> "+y
set number
"set relativenumber
set nocompatible
set ignorecase
syntax on
set wildmode=longest,list
set ttyfast
set wildmode=longest,list
set autoindent
set smartindent
nnoremap <C-e> :NvimTreeToggle<CR>
nnoremap <S-e> :NvimTreeFocus<CR>
call plug#begin()
Plug 'EdenEast/nightfox.nvim',
Plug 'nvim-tree/nvim-tree.lua'
Plug 'nvim-tree/nvim-web-devicons'
Plug 'nvim-lua/plenary.nvim'
Plug 'lewis6991/gitsigns.nvim'
call plug#end()
colorscheme carbonfox
lua << EOF
require('gitsigns').setup()
EOF
lua << EOF
require("nvim-tree").setup({
  view = {
    width = 30,
  },
  renderer = {
    group_empty = true,
  },
})
EOF

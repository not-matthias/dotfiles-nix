" TODO: https://github.com/jonhoo/configs/blob/master/editor/.config/nvim/init.vim

set rtp +=~/.vim

"  TODO:
"  sneak
"  toggleterm (https://github.com/akinsho/toggleterm.nvim)
"  copilot (tab not working)
"  format on save (https://github.com/mhartington/formatter.nvim)_
"  tabline(https://github.com/kdheepak/tabline.nvim)
"  https://github.com/windwp/nvim-ts-autotag
"  https://github.com/numToStr/Comment.nvim
"  https://github.com/ThePrimeagen/harpoon
"  https://github.com/lewis6991/gitsigns.nvim
"  https://github.com/phaazon/hop.nvim
"  ctrl+b for file explorer (https://github.com/kyazdani42/nvim-tree.lua)
"  other stuff https://github.com/jonhoo/configs/blob/master/editor/.config/nvim/init.vim

" #####################################################
" Lua
" #####################################################"
" lua require("plugins")

" #####################################################
" Plugins
" #####################################################
" source ~/.config/nvim/modules/vim-plug.vim

" #####################################################
"	Configuration
" #####################################################

" Permanent undo
set undodir=~/.vimdid
set undofile
set hidden

syntax on

"  Reload shortcut
nnoremap <leader>r :source ~/.config/nvim/init.vim<CR>

" #####################################################
"	Modules
" #####################################################

" source ~/.config/nvim/modules/rust.vim
" source ~/.config/nvim/modules/toggleterm.vim
" source ~/.config/nvim/modules/colorizer.vim
" source ~/.config/nvim/modules/tree.vim
" source ~/.config/nvim/modules/telescope.vim
" source ~/.config/nvim/modules/cmp.vim
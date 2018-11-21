set nocompatible
set enc=utf-8
"-显示行号：
"set number
"-启用插件：filetype
filetype plugin on
set history=500
syntax on
set autoindent
set smartindent
"-显示括号匹配
set showmatch
"-显示状态
set ruler
"-关闭高亮匹配
"set nohls
"-启用快速搜索
set incsearch
"-启用paste模式
set paste
"设置tabstop
set ts=4
"设置shiftwidth
set sw=4
"设置expandtab
set et
 
if has("autocmd")
filetype plugin indent on
endif
autocmd filetype python setlocal et sta sw=4 sts=4
"-根据文件后缀增加指定内容到行首
func SetTitle()
if &filetype == 'sh'
call setline(1, "\#!/bin/bash")
call append(line("."), "\# ")
call append(line(".")+1, "")
else
call setline(1, "\#!/bin/env python")
call append(line("."), "\# ")     
call append(line(".")+1, "")
endif
endfunc
 
autocmd BufNewFile *.py,*.sh exec ":call SetTitle()"
"-跳转到EOF的位置
autocmd BufNewFile * normal G
"-按下 F2 删除空行
nnoremap <F2> :g/^\s*$/d<CR>

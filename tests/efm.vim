let &errorformat ='%f:%s:%m'
cgetexpr ['efm.vim:" bar:baz']
echomsg string(getqflist())
copen
cc

" bar baz
" bar
" foo bar

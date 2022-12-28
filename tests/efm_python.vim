let contents = readfile("tests/output_from_vim_test.txt")
let &errorformat ='%f:%l: %m'
" cgetexpr ['            stock_winners/domain.py:28: Exception']
cgetexpr contents
" echomsg string(getqflist())
copen
" cc

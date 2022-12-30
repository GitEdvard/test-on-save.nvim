-- local contents = vim.fn.readfile("tests/cs_output_failing.txt")
-- local contents = vim.fn.readfile("tests/cs_output_working.txt")
vim.cmd([[
:set errorformat=%m\ in\ %f:line\ %l
:set errorformat+=\ %f(%l\\\,%c):\ %m
let contents = readfile("tests/cs_output_working.txt")
" let contents = readfile("tests/cs_output_failing.txt")
cgetexpr contents
copen
]])

-- vim.cmd{ cmd = 'cgetexpr', args = {contents} }

local contents = vim.fn.readfile("tests/output_from_vim_test.txt")
vim.cmd([[
let &errorformat ='%f:%l: %m'
]])
local contents_str = '[\'' .. table.concat(contents, '\',\'') .. '\']'

vim.cmd{ cmd = 'cgetexpr', args = {contents_str} }

-- vim.cmd.copen()

-- vim.cmd("CTRL-W_L")
-- require'os'
-- require'io'
-- local tmpname = os.tmpname()
-- local f = io.open(tmpname, "w")
-- -- print(vim.inspect(getmetatable(f)))
-- f:write(contents_str)
-- f:close()
-- local g = io.open(tmpname, "r")
-- print(g:read("*a"))
-- g:close()
-- os.remove(tmpname)

-- print(type(contents_str))
-- f.write(contents_str)

-- vim.cmd{ cmd = 'cgetexpr', args =  { "['             stock_winners/domain.py:28: Exception']" }}

-- vim.cmd([[
-- let contents = readfile("tests/output_from_vim_test.txt")
-- cgetexpr contents
-- ]])


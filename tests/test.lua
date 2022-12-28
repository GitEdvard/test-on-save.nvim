local open = io.open
local function read_file(path)
    local file = open(path, "r") -- r read mode and b binary mode
    if not file then return nil end
    local content = file:read "*a" -- *a or *all reads the whole file
    file:close()
    return content
end

local file_content = read_file("lua/UnitTest1.cs")

local ts = require'vim.treesitter'

local query_string = [[
(
(method_declaration
name: (identifier) @name)
(#eq? @name "Test2")
)
]]

local query_string_old = [[
(
(method_declaration
name: (identifier) @name)
)
]]

local query_for_class = [[
(
(class_declaration
name: (identifier) @name)
)
]]

local find_node = function(contents, query_string)
    local query = ts.parse_query("c_sharp", query_string)
    local parser = ts.get_string_parser(contents, "c_sharp", {})
    local tree = parser:parse()[1]
    local root = tree:root()
    for id, node in query:iter_captures(root, contents, 0, -1) do
        if id == 1 then
            local start = { node:start() }
            local start_byte = start[3]
            local end_ = { node:end_() }
            local end_byte = end_[3]
            return { start_byte, end_byte }
            -- return node
        end
    end
    return nil
end

local mynode = find_node(file_content, query_for_class)
-- print(string.sub(file_content, mynode[1], mynode[2]))
local mynode = find_node(file_content, query_string)
-- print(string.sub(file_content, mynode[1], mynode[2]))
-- print(vim.inspect(mynode))

local type_patterns = {
    ['class'] = "class query",
    ['method'] = "query_for_method",
}

type_patterns['added'] = "something"
 for k in pairs(type_patterns) do
     print(k)
     print(type_patterns[k])
 end

local unpacked = unpack(type_patterns)
print(unpacked)

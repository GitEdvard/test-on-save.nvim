local query_module = require'vim.treesitter.query'
local ts = vim.treesitter
local L = require'test_on_save_core'

local M = {}

M.call_execute_query = function(query_list)
    local bufnr = vim.api.nvim_get_current_buf()
    local search_hit = L.execute_query(bufnr, query_list, "python")
    return search_hit
end

M.to_vim_script_arr = function(lua_table)
    -- lua table contains strings only. Escape each single quote in it
    local escaped_table = {}
    for _, v in ipairs(lua_table) do
        local row = string.gsub(v, "'", "''")
        table.insert(escaped_table, row)
    end
    return '[\'' .. table.concat(escaped_table, '\',\'') .. '\']'
end

M.fetch_text_at_cursor = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local search_hit = L.get_text_at_cursor(bufnr)
    return search_hit
end

M.matches_pattern = function(node, query_list)
    local node_type = node:type()
    local is_valid = false
    local matching_pattern = ""
    for node_type_identifier in pairs(query_list) do
        if node_type:find(node_type_identifier) then
            is_valid = true
            matching_pattern = node_type_identifier
            break
        end
    end
    return is_valid, matching_pattern
end

M.get_node_text = function(start_node, bufnr, query_string, lang)
    local query = query_module.parse(lang, query_string)
    for id, node in query:iter_captures(start_node, bufnr, 0, -1) do
        if id == 1 then
            local node_text = ts.get_node_text(node, bufnr)
            return node_text
        end
    end
    return nil
end

M.get_multiple_node_texts = function(start_node, bufnr, query_string, lang)
    local query = query_module.parse(lang, query_string)
    local node_texts = {}
    for id, node in query:iter_captures(start_node, bufnr, 0, -1) do
        local node_text = ts.get_node_text(node, bufnr)
        table.insert(node_texts, node_text)
    end
    return node_texts
end

M.query_for_superclass = [[
(
(class_definition
superclasses: (argument_list (identifier) @name))
)
]]

M.query_for_class = [[
(
(class_definition
name: (identifier) @name)
)
]]

M.query_for_function = [[
(
(function_definition
name: (identifier) @name)
)
]]

M.query_for_methods = [[
(class_definition
body: (block
[
(function_definition
name: (identifier) @method.name)
(decorated_definition
(function_definition
  name: (identifier) @method.name))
]))
]]

return M


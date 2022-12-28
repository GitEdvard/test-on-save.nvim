local query_module = require'vim.treesitter.query'
local ts_utils = require'nvim-treesitter.ts_utils'
local ts = require'vim.treesitter'

-- Trim spaces and opening brackets from end
local transform_line = function(line)
    return line:gsub('%s*[%[%(%{]*%s*$', '')
end

local query_for_method = [[
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

local matches_pattern = function(node, type_patterns)
    local node_type = node:type()
    local is_valid = false
    local matching_pattern = ""
    for rgx in pairs(type_patterns) do
        if node_type:find(rgx) then
            is_valid = true
            matching_pattern = rgx
            break
        end
    end
    return is_valid, matching_pattern
end

local get_node_text = function(start_node, bufnr, query_string)
    local query = ts.parse_query("c_sharp", query_string)
    for id, node in query:iter_captures(start_node, bufnr, 0, -1) do
        if id == 1 then
            return query_module.get_node_text(node, bufnr)
        end
    end
    return nil
end

function get_unit_test_range(bufnr, type_patterns)
    local options = {}
    local indicator_size = 100
    local transform_fn = transform_line

    local current_node = ts_utils.get_node_at_cursor()
    if not current_node then return "" end

    local lines = {}
    local expr = current_node

    while expr do
        local matches, matching_pattern = matches_pattern(expr, type_patterns)
        if matches then
            local method_node = expr
            local text = get_node_text(method_node, bufnr, type_patterns[matching_pattern])
            table.insert(lines, 1, text)
        end
        expr = expr:parent()
    end
    text = table.concat(lines, ".")
    return text
end

local scope_for_method = function(bufnr)
    local type_patterns = {
        ['class'] = query_for_class,
        ['method'] = query_for_method,
    }
    local text = get_unit_test_range(bufnr, type_patterns)
    return vim.inspect(text)
end

local scope_for_class = function(bufnr)
    local type_patterns = {
        ['class'] = query_for_class,
    }
    local text = get_unit_test_range(bufnr, type_patterns)
    return vim.inspect(text)
end

local attach_test_range = function(bufnr, scope, write_range_fnc)
    local command = { "dotnet", "test", "--filter", "FullyQualifiedName~" .. scope }
    local group = vim.api.nvim_create_augroup("edvard-automagic", { clear = true })
    vim.api.nvim_create_autocmd("BufWritePost", {
        group = group,
        pattern = "*.cs",
        callback = function()
            vim.fn.jobstart(command, {
                stdout_buffered = true,
                on_stdout = function(_, data)
                    if not data then
                        return
                    end
                    local str_data = table.concat(data, "\n")
                    vim.cmd { cmd = 'cexpr', args = {vim.inspect(str_data)} }
                end,
            } )
        end
    })
end

vim.api.nvim_create_user_command("AttachTestMethod", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local scope = scope_for_method(bufnr)
    attach_test_range(bufnr, scope)
end, {})

vim.api.nvim_create_user_command("AttachTestClass", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local scope = scope_for_class(bufnr)
    attach_test_range(bufnr, scope)
end, {})


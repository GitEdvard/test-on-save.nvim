local M = require('test_on_save_common')

local query_for_function = [[
(
(function_definition
name: (identifier) @name)
)
]]

local scope_for_function = function(bufnr)
    local type_patterns = {
        ['function'] = query_for_function,
    }
    local method_name = M.get_unit_test_range(bufnr, type_patterns, "python")
    local text = vim.fn.expand('%') .. "::" .. method_name
    return vim.inspect(text)
end

local scope_for_suite = function(bufnr)
    local text = vim.fn.expand('%')
    return vim.inspect(text)
end



vim.api.nvim_create_user_command("AttachTestMethod", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local scope = scope_for_function(bufnr)
    local command = "python -m pytest " .. scope .." 2>&1"
    M.attach_test_range(bufnr, command, "*.py")
end, {})

vim.api.nvim_create_user_command("AttachTestClass", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local scope = scope_for_suite(bufnr)
    local command = "python -m pytest " .. scope .." 2>&1"
    M.attach_test_range(bufnr, command, "*.py")
end, {})


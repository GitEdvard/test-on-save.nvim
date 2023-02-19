local M = require('test_on_save_core')
local R = require('run_tests')

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

local scope_for_method = function(bufnr)
    local type_patterns = {
        ['class'] = query_for_class,
        ['method'] = query_for_method,
    }
    local text = M.get_unit_test_range(bufnr, type_patterns, "java")
    return vim.inspect(text)
end

local scope_for_class = function(bufnr)
    local type_patterns = {
        ['class'] = query_for_class,
    }
    local text = M.get_unit_test_range(bufnr, type_patterns, "java")
    return vim.inspect(text)
end

local java_parser = function(row)
  return require'java_test_parser'.parse_row(row)
end

vim.api.nvim_create_user_command("AttachTestMethod", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local scope = scope_for_method(bufnr)
    local command = "mvn test -DtrimStackTrace=false -Dtest=" .. scope 
    M.attach_test_range(bufnr, command, "*.java", java_parser)
end, {})

vim.api.nvim_create_user_command("AttachTestClass", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local scope = scope_for_class(bufnr)
    local command = "mvn test -DtrimStackTrace=false -Dtest=" .. scope 
    M.attach_test_range(bufnr, command, "*.java", java_parser)
end, {})

vim.api.nvim_create_user_command("RunTestMethod", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local scope = scope_for_method(bufnr)
    local command = "mvn test -DtrimStackTrace=false -Dtest=" .. scope 
    R.run_test(command, java_parser)
end, {})

vim.api.nvim_create_user_command("RunTestClass", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local scope = scope_for_class(bufnr)
    local command = "mvn test -DtrimStackTrace=false -Dtest=" .. scope 
    R.run_test(command, java_parser)
end, {})

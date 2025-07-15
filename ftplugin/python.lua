local Job = require('plenary.job')
local M = require('test_on_save_core')
local R = require('run_tests')
require('utils')

local query_for_function = [[
(
(function_definition
name: (identifier) @name)
)
]]

local query_for_class = [[
(
(class_definition
name: (identifier) @name)
)
]]

local extract_method_name = function(bufnr)
    local type_patterns = {
        ['function'] = query_for_function,
    }
    local method_name = M.execute_query(bufnr, type_patterns, "python")
    return method_name
end

local scope_for_function = function(bufnr)
    local type_patterns = {
        ['function'] = query_for_function,
    }
    local method_name = M.execute_query(bufnr, type_patterns, "python")
    local text = vim.fn.expand('%') .. " -k '" .. method_name .. "'"
    return text
end

local scope_for_suite = function(bufnr)
    local text = vim.fn.expand('%')
    return vim.inspect(text)
end



vim.api.nvim_create_user_command("AttachTestMethod", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local scope = scope_for_function(bufnr)
    local command = "python -m pytest -vv " .. scope .." 2>&1"
    print("command")
    print(command)
    M.attach_test_range(bufnr, command, "*.py")
end, {})

vim.api.nvim_create_user_command("AttachTestClass", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local scope = scope_for_suite(bufnr)
    local command = "python -m pytest -vv " .. scope .." 2>&1"
    M.attach_test_range(bufnr, command, "*.py")
end, {})

vim.api.nvim_create_user_command("RunTestMethod", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local scope = scope_for_function(bufnr)
    local command = "python -m pytest -vv " .. scope .." 2>&1"
    R.run_test(command)
end, {})

vim.api.nvim_create_user_command("RunTestClass", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local scope = scope_for_suite(bufnr)
    local command = "python -m pytest -vv " .. scope .." 2>&1"
    R.run_test(command)
end, {})

vim.api.nvim_create_user_command("RunInheritedTestMethod", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local cwd = vim.fn.getcwd()
    local query_list = {
        ['class'] = query_for_class,
    }
    local current_class_name = M.execute_query(bufnr, query_list, "python")
    local search_text = current_class_name
    grepper = Job:new({
      command = "rg",
      args = {"--vimgrep", "--type", "py", "-w", search_text, cwd},
      cwd = cwd,
    })
    local rg_hits = grepper:sync()
    super_class_hits = {}
    for _, single_rg_hit in pairs(rg_hits) do
      if string.find(single_rg_hit, "class %w*%(".. search_text .. "%)") then
        table.insert(super_class_hits, single_rg_hit)
      end
    end
    if #super_class_hits > 0 then
      local first_hit = super_class_hits[1]
      local _, _, file_path = string.find(first_hit, "(.*%.py):.*")
      local method_name = extract_method_name(bufnr)
      local command = "python -m pytest -vv " .. file_path .. " -k '" .. method_name .. "' 2>&1"
      R.run_test(command)
    end
end, {})

vim.api.nvim_create_user_command("DetachTestRange", function()
    M.detach_test_range()
end, {})

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

local find_sub_classes = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local cwd = vim.fn.getcwd()
    local query_list = {
        ['class'] = query_for_class,
    }
    local current_class_name = M.execute_query(bufnr, query_list, "python")
    if current_class_name == "" or current_class_name == nil then
      return {}
    end
    local search_text = current_class_name
    grepper = Job:new({
      command = "rg",
      args = {"--vimgrep", "--type", "py", "-w", search_text, cwd},
      cwd = cwd,
    })
    local rg_hits = grepper:sync()
    sub_class_hits = {}
    for _, single_rg_hit in pairs(rg_hits) do
      if string.find(single_rg_hit, "class %w*%(".. search_text .. "%)") then
        table.insert(sub_class_hits, single_rg_hit)
      end
    end
    return sub_class_hits
end

local extract_subclasses = function(sub_class_hits)
    local first_hit = sub_class_hits[1]
    local file_path_list = {}
    for _, hit in pairs(sub_class_hits) do
      local _, _, file_path = string.find(hit, "(.*%.py):.*")
      table.insert(file_path_list, file_path)
    end
    local files_string = table.concat(file_path_list, " ")
    return files_string
end

vim.api.nvim_create_user_command("RunTestMethod", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local sub_class_hits = find_sub_classes()
    if #sub_class_hits > 0 then
      local files_string = extract_subclasses(sub_class_hits)
      local method_name = extract_method_name(bufnr)
      local command = "python -m pytest -vv " .. files_string .. " -k '" .. method_name .. "' 2>&1"
      R.run_test(command)
    else
      local scope = scope_for_function(bufnr)
      local command = "python -m pytest -vv " .. scope .." 2>&1"
      R.run_test(command)
    end
end, {})

vim.api.nvim_create_user_command("RunTestClass", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local sub_class_hits = find_sub_classes()
    if #sub_class_hits > 0 then
      local files_string = extract_subclasses(sub_class_hits)
      local command = "python -m pytest -vv " .. files_string .. " 2>&1"
      R.run_test(command)
    else
      local scope = scope_for_suite(bufnr)
      local command = "python -m pytest -vv " .. scope .." 2>&1"
      R.run_test(command)
    end
end, {})

vim.api.nvim_create_user_command("AttachTestClass", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local sub_class_hits = find_sub_classes()
    if #sub_class_hits > 0 then
      local files_string = extract_subclasses(sub_class_hits)
      local command = "python -m pytest -vv " .. files_string .. " 2>&1"
      M.attach_test_range(bufnr, command, "*.py")
    else
      local scope = scope_for_suite(bufnr)
      local command = "python -m pytest -vv " .. scope .." 2>&1"
      M.attach_test_range(bufnr, command, "*.py")
    end
end, {})

vim.api.nvim_create_user_command("AttachTestMethod", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local sub_class_hits = find_sub_classes()
    if #sub_class_hits > 0 then
      local files_string = extract_subclasses(sub_class_hits)
      local method_name = extract_method_name(bufnr)
      local command = "python -m pytest -vv " .. files_string .. " -k '" .. method_name .. "' 2>&1"
      print("command")
      print(command)
      M.attach_test_range(bufnr, command, "*.py")
    else
      local scope = scope_for_function(bufnr)
      local command = "python -m pytest -vv " .. scope .." 2>&1"
      print("command")
      print(command)
      M.attach_test_range(bufnr, command, "*.py")
    end
end, {})

vim.api.nvim_create_user_command("DetachTestRange", function()
    M.detach_test_range()
end, {})

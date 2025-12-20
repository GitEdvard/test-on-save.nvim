local Job = require('plenary.job')
local M = require('test_on_save_core')
local R = require('run_tests')
local pickers = require "telescope.pickers"
local conf = require("telescope.config").values
local finders = require "telescope.finders"
local make_entry = require "telescope.make_entry"
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
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

local current_selected_class_scope = ""

local mystate = require("mystate")

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

local class_name_from_rg_hit = function(single_rg_hit)
  local class_name_cand2 = single_rg_hit:match(".*class (.*)%(.*%).*")
  if class_name_cand2 ~= nil then 
    return class_name_cand2
  end
  local class_name_cand1 = single_rg_hit:match(".*class (.*):")
  return class_name_cand1
end

local find_subclasses_from_class = function(super_class_name)
    local search_text = "class .*?\\((.* ,)?\\b" ..  super_class_name .."\\b(, .*)?\\)"
    local cwd = vim.fn.getcwd()
    grepper = Job:new({
      command = "rg",
      args = {"--vimgrep", "--type", "py", "-e", search_text, cwd},
      cwd = cwd,
    })
    local rg_hits = grepper:sync()
    local filtered_hits = {}
    for _, value in pairs(rg_hits) do
      -- Match whole word only
      if not value:find("%f[%a]tests%f[%A]") then
        table.insert(filtered_hits, value)
      end
    end
    return filtered_hits
end


find_subclasses_rec2 = function(root_class, rg_hits)
  local hits = find_subclasses_from_class(root_class)
  for _, single_rg_hit in pairs(hits) do
    table.insert(rg_hits, single_rg_hit)
    local class_name = class_name_from_rg_hit(single_rg_hit)
    local class_name_trimmed = class_name:gsub("%s+", "")
    find_subclasses_rec2(class_name_trimmed, rg_hits)
  end
  return rg_hits
end

local selection_picker = function(title, contents_table, on_select)
  local bufnr = vim.api.nvim_get_current_buf()
  local opts = {}
  pickers.new(opts, {
    prompt_title = title,
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        selection = action_state.get_selected_entry()
        if on_select then
          mystate.last_pick = on_select(selection, bufnr)
        end
        actions.close(prompt_bufnr)
      end)
      return true
    end,
    finder = finders.new_table {
      results = contents_table,
      entry_maker = opts.entry_maker or make_entry.gen_from_vimgrep(opts)
    },
    previewer = conf.grep_previewer(opts),
    sorter = conf.generic_sorter(opts),
    push_cursor_on_edit = true,
  }):find()
end


local extract_method_name = function(bufnr)
    local type_patterns = {
        ['function'] = query_for_function,
    }
    local method_name = M.execute_query(bufnr, type_patterns, "python")
    return method_name
end

local scope_for_function = function(bufnr)
    local method_pattern = {
        ['function'] = query_for_function,
    }
    local method_name = M.execute_query(bufnr, method_pattern, "python")
    local text = vim.fn.expand('%') .. " -k '" .. method_name .. "'"
    return text
end

local scope_for_function_unique = function(bufnr)
    local method_pattern = {
        ['function'] = query_for_function,
    }
    local class_pattern = {
        ['class'] = query_for_class,
    }
    local method_name = M.execute_query(bufnr, method_pattern, "python")
    local class_name = M.execute_query(bufnr, class_pattern, "python")
    local text = ""
    if class_name then
      text = vim.fn.expand('%') .. "::" .. class_name .. "::" .. method_name
    else
      text = vim.fn.expand('%') .. "::" .. method_name
    end
    return text
end

local scope_for_suite = function(bufnr)
    local text = vim.fn.expand('%')
    return vim.inspect(text)
end

local contains = function(tbl, str)
  for _, v in ipairs(tbl) do 
    if v == str then
      return true
    end
  end
  return false
end

local extract_subclasses = function(sub_class_hits)
    local first_hit = sub_class_hits[1]
    local file_path_list = {}
    for _, hit in pairs(sub_class_hits) do
      local _, _, file_path = string.find(hit, "(.*%.py):.*")
      if not contains(file_path_list, file_path) then
        table.insert(file_path_list, file_path)
      end
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

local attach_single_method_from_class = function(class_scope, bufnr)
  local method_name = extract_method_name(bufnr)
  local scope = class_scope.."::"..method_name
  local command = "python -m pytest -vv " .. scope .." 2>&1"
  print("command")
  print(command)
  M.attach_test_range(bufnr, command, "*.py")
  return class_scope
end

attach_single_method = function(selection, bufnr)
  local class_name = string.match(selection.text, "class%s+(%w+)%(.*%)")
  local file_path = selection.filename
  class_scope = file_path.."::"..class_name
  return attach_single_method_from_class(class_scope, bufnr)
end

local attach_method_for_current_class = function(bufnr)
    local scope = scope_for_function_unique(bufnr)
    local command = "python -m pytest -vv " .. scope .." 2>&1"
    print("command")
    print(command)
    M.attach_test_range(bufnr, command, "*.py")
end

vim.api.nvim_create_user_command("AttachTestMethodUnique", function()
    local bufnr = vim.api.nvim_get_current_buf()
    if mystate.last_pick ~= nil and mystate.last_pick ~= "" then
      return attach_single_method_from_class(mystate.last_pick, bufnr)
    end
    local acc_rg_hits = {}
    local query_list = {
        ['class'] = query_for_class,
    }
    local current_class_name = M.execute_query(bufnr, query_list, "python")
    local sub_class_hits = find_subclasses_rec2(current_class_name, acc_rg_hits)
    if #sub_class_hits > 0 then
      selection_picker("Pick class to run", sub_class_hits, attach_single_method)
      return 
    else
      attach_method_for_current_class(bufnr)
    end
end, {})

vim.api.nvim_create_user_command("DetachTestRange", function()
    M.detach_test_range()
end, {})

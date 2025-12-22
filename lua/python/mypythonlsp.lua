local N = {}
local M = require'test_on_save_core'
local Job = require('plenary.job')
local pickers = require "telescope.pickers"
local conf = require("telescope.config").values
local finders = require "telescope.finders"
local make_entry = require "telescope.make_entry"
local ts_utils = require'nvim-treesitter.ts_utils'
local query_for_superclass = require'treesitter.my_utils'.query_for_superclass
local query_for_class = require'treesitter.my_utils'.query_for_class
local query_for_function = require'treesitter.my_utils'.query_for_function
local query_for_methods = require'treesitter.my_utils'.query_for_methods
local call_execute_query = require'treesitter.my_utils'.call_execute_query
local to_vim_script_arr = require'treesitter.my_utils'.to_vim_script_arr
local fetch_text_at_cursor = require'treesitter.my_utils'.fetch_text_at_cursor
local matches_pattern = require'treesitter.my_utils'.matches_pattern
local get_node_text = require'treesitter.my_utils'.get_node_text
local get_multiple_node_texts = require'treesitter.my_utils'.get_multiple_node_texts

local latest_search_type = ""
local latest_search_text = ""
local latest_prefix_text = ""
local latest_filter_text = ""
local latest_instantiation_list = {}

local filter_rg_hits = function(rg_hits, filter_text)
    local filtered_hits = {}
    for _, value in pairs(rg_hits) do
      -- Match whole word only
      if not value:find("%f[%a]"..filter_text.."%f[%A]") then
        table.insert(filtered_hits, value)
      end
    end
    return filtered_hits
end

local find_with_rg_from_str = function(search_text)
    local cwd = vim.fn.getcwd()
    grepper = Job:new({
      command = "rg",
      args = {"--vimgrep", "--type", "py", "-w", search_text, cwd},
      cwd = cwd,
    })
    local rg_hits = grepper:sync()
    return rg_hits
end

local find_class_name_and_rg_hit = function(query)
  local query_list = {
      ['class'] = query,
  }
  local bufnr = vim.api.nvim_get_current_buf()
  local cwd = vim.fn.getcwd()
  local search_hit = M.execute_query(bufnr, query_list, "python")
  local rg_hits = {}
  if search_hit ~= nil and search_hit ~= "" then
    rg_hits = find_with_rg_from_str("class " .. search_hit)
  end
  return search_hit, rg_hits
end


local find_with_prefix = function(query_list, prefix)
    local bufnr = vim.api.nvim_get_current_buf()
    local cwd = vim.fn.getcwd()
    local search_hit = M.execute_query(bufnr, query_list, "python")
    if search_hit == "" or search_hit == nil then
      return {}
    end
    local search_text = prefix .. search_hit
    grepper = Job:new({
      command = "rg",
      args = {"--vimgrep", "--type", "py", "-w", search_text, cwd},
      cwd = cwd,
    })
    local rg_hits = grepper:sync()
    return rg_hits
end


local find_super_class_name = function()
    local query_list = {
        ['class'] = query_for_superclass,
    }
    return call_execute_query(query_list)
end

local find_super_class = function()
    local query_list = {
        ['class'] = query_for_superclass,
    }
    local prefix = "class "
    return find_with_prefix(query_list, prefix)
end

local find_subclasses = function(super_class_name)
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

local class_name_from_rg_hit = function(single_rg_hit)
  local class_name_cand2 = single_rg_hit:match(".*class (.*)%(.*%).*")
  if class_name_cand2 ~= nil then 
    return class_name_cand2
  end
  local class_name_cand1 = single_rg_hit:match(".*class (.*):")
  return class_name_cand1
end

find_subclasses_rec = function(root_class, rg_hits)
  local hits = find_subclasses(root_class)
  for _, single_rg_hit in pairs(hits) do
    table.insert(rg_hits, single_rg_hit)
    local class_name = class_name_from_rg_hit(single_rg_hit)
    local class_name_trimmed = class_name:gsub("%s+", "")
    find_subclasses_rec(class_name_trimmed, rg_hits)
  end
  return rg_hits
end

local find_sibling_classes = function(query_list)
    local bufnr = vim.api.nvim_get_current_buf()
    local cwd = vim.fn.getcwd()
    local search_hit = M.execute_query(bufnr, query_list, "python")
    if search_hit == "" or search_hit == nil then
      return {}
    end
    local search_text = "class .*?\\((.* ,)?\\b" ..  search_hit .."\\b(, .*)?\\)"
    grepper = Job:new({
      command = "rg",
      args = {"--vimgrep", "--type", "py", "-e", search_text, cwd},
      cwd = cwd,
    })
    local rg_hits = grepper:sync()
    local filtered_hits = {}
    for _, value in pairs(rg_hits) do
      -- Match whole word "def" only
      if not value:find("%f[%a]tests%f[%A]") then
        table.insert(filtered_hits, value)
      end
    end
    return filtered_hits
end

local find_with_rg = function(search_text, search_prefix, filter_text)
    if search_text == "" or search_text == nil then
      return {}
    end
    if not (search_prefix == nil) and not (search_prefix == "") then
      search_text = search_prefix .. " " .. search_text
    end
    local cwd = vim.fn.getcwd()
    grepper = Job:new({
      command = "rg",
      args = {"--vimgrep", "--type", "py", "--glob", "!tests", "-w", search_text, cwd},
      cwd = cwd,
    })
    local rg_hits = grepper:sync()
    if filter_text == nil or filter_text == "" then
      return rg_hits
    end
    local filtered_hits = {}
    for _, value in pairs(rg_hits) do
      -- Match whole word "def" only
      if not value:find("%f[%a]"..filter_text.."%f[%A]") then
        table.insert(filtered_hits, value)
      end
    end
    return filtered_hits
end

local find_method_text = function()
    local query_list = {
        ['function'] = query_for_function,
    }
    return call_execute_query(query_list)
end

local show_picker = function(title, contents_table)
  local opts = {}
  pickers.new(opts, {
    prompt_title = title,
    finder = finders.new_table {
      results = contents_table,
      entry_maker = opts.entry_maker or make_entry.gen_from_vimgrep(opts)
    },
    previewer = conf.grep_previewer(opts),
    sorter = conf.generic_sorter(opts),
    push_cursor_on_edit = true,
  }):find()
end

N.find_current_method_name = function()
    local query_list = {
        ['function'] = query_for_function,
    }
    local bufnr = vim.api.nvim_get_current_buf()
    local cwd = vim.fn.getcwd()
    local search_hit = M.execute_query(bufnr, query_list, "python")
    return search_hit
end

N.find_current_class_name = function()
    local query_list = {
        ['class'] = query_for_class,
    }
    local bufnr = vim.api.nvim_get_current_buf()
    local cwd = vim.fn.getcwd()
    local search_hit = M.execute_query(bufnr, query_list, "python")
    return search_hit
end

N.show_method_definitions = function()
  local method_text = find_method_text()
  local method_definitions = find_with_rg(method_text, "def", "")
  latest_search_text = method_text
  latest_prefix_text = "def"
  latest_filter_text = ""
  latest_search_type = "method"
  show_picker("Find methods", method_definitions)
end

local show_method_usages_local = function(method_text)
  local method_usages = find_with_rg(method_text, "", "def")
  latest_search_text = method_text
  latest_prefix_text = ""
  latest_filter_text = "def"
  latest_search_type = "method"
  show_picker("Methods usages", method_usages)
end


N.show_method_usages = function()
  local method_text = find_method_text()
  if method_text == "__init__" or method_text == "" then
    N.show_class_instantiation()
  else
    show_method_usages_local(method_text)
  end
end

N.goto_superclass = function()
  super_class_hits = find_super_class()
  super_class_hits_arr = to_vim_script_arr(super_class_hits)
  P(super_class_hits_arr)
  vim.cmd { cmd = 'cgetexpr', args = {super_class_hits_arr} }
  vim.cmd { cmd = 'cfirst'}
end

local find_root_super_class_name = function()
  local next_candidate_super_class = find_super_class_name()
  local latest_super_class = ""
  local latest_rg_hits = {}
  local rg_hits = {}
  if next_candidate_super_class ~= nil and next_candidate_super_class ~= "" then
    rg_hits = find_with_rg_from_str("class " .. next_candidate_super_class)
  end
  if #rg_hits == 0 then
    latest_super_class, latest_rg_hits = find_class_name_and_rg_hit(query_for_class)
  end
  while #rg_hits > 0 do
    latest_super_class = next_candidate_super_class
    latest_rg_hits = rg_hits
    first_rg_hit = rg_hits[1]
    rg_hits = {}
    local within_params = first_rg_hit:match("%((.*)%)")
    local within_params_trimmed = within_param and within_params:gsub("%s+", "") or nil
    if within_params_trimmed ~= "" and within_params_trimmed ~= nil then
      local class_list = mysplit(within_params, ",")
      next_candidate_super_class = class_list[1]
      rg_hits = find_with_rg_from_str("class " .. next_candidate_super_class)
    end
  end
  return latest_super_class, latest_rg_hits
end

N.show_class_family = function()
  local root_super_class_name, rg_hits_for_root = find_root_super_class_name()
  local accumulated_hits = rg_hits_for_root
  find_subclasses_rec(root_super_class_name, accumulated_hits)
  show_picker("Class family", accumulated_hits)
end

local show_method_usages_caret = function(text_at_cursor)
  local method_usages = find_with_rg(text_at_cursor, "", "def")
  latest_search_text = text_at_cursor
  latest_prefix_text = ""
  latest_filter_text = "def"
  latest_search_type = "method"
  show_picker("Methods usages", method_usages)
end

N.show_method_usages_caret = function()
  local text_at_cursor = fetch_text_at_cursor()
  if text_at_cursor == "__init__" then
    N.show_class_instantiation()
  else
    show_method_usages_caret(text_at_cursor)
  end
end

N.show_method_definitions_caret = function()
  local text_at_cursor = fetch_text_at_cursor()
  local method_definitions = find_with_rg(text_at_cursor, "def", "")
  latest_search_text = text_at_cursor
  latest_prefix_text = "def"
  latest_filter_text = ""
  latest_search_type = "method"
  show_picker("Method definitions", method_definitions)
end

-- remove
N.show_sibbling_classes = function()
  local query_list = {
      ['class'] = query_for_superclass,
  }
  siblings = find_sibling_classes(query_list)
  show_picker("Sibling classes", siblings)
end

N.show_subclasses = function()
  local current_class_name, rg_hit = find_class_name_and_rg_hit(query_for_class)
  local accumulated_hits = rg_hit
  find_subclasses_rec(current_class_name, accumulated_hits)
  show_picker("Subclasses", accumulated_hits)
end

N.show_latest_method_search = function()
  if latest_search_type == "method" then
    local method_definitions = find_with_rg(latest_search_text, latest_prefix_text, latest_filter_text)
    show_picker("Find methods", method_definitions)
  end
  if latest_search_type == "class" then
    show_picker("Find instantiations", latest_instantiation_list)
  end
end

N.find_classes = function()
  print("hello")
end

local find_factory_instantiations = function(instantiation_list, query_list_for_methods, bufnr)
    local instantiation_list_copy = vim.deepcopy(instantiation_list)
    local current_node = ts_utils.get_node_at_cursor()
    if not current_node then return {} end
    local method_names = {}
    local make_method_usages = {}
    local expr = current_node
    while expr do
        local matches, matching_pattern = matches_pattern(expr, query_list_for_methods)
        if matches then
            local method_node = expr
            local text_list = get_multiple_node_texts(method_node, bufnr, query_list_for_methods[matching_pattern], "python")
            vim.list_extend(method_names, text_list)
        end
        expr = expr:parent()
    end
    local search_patterns = { "^make_", "^get_knowledge_base", "create_all_pages"}
    local make_method_name = nil
    for _, v in ipairs(method_names) do
      for _, p in ipairs(search_patterns) do
        if v:match(p) then
          make_method_name = v
          break
        end
      end
    end
    if make_method_name ~= nil then
      local method_usages = find_with_rg(make_method_name, "", "def")
      vim.list_extend(make_method_usages, method_usages)
    end
    vim.list_extend(instantiation_list_copy, make_method_usages)
    return instantiation_list_copy
end

local find_instantiations = function(rg_hits)
  local instantiation_list = {}
  local query_list_for_methods = {
    ['class'] = query_for_methods
  }
  local query_list_for_class = {
    ['class'] = query_for_class,
  }
  for _, v in pairs(rg_hits) do
    -- Remove last part of rg output, to let it fit into python patterns
    local filtered = v:match("^([^:]*:[^:]*:)").." "
    rg_hit_arr = to_vim_script_arr({filtered})
    vim.cmd { cmd = 'cgetexpr', args = {rg_hit_arr} }
    vim.cmd { cmd = 'cfirst'}
    local bufnr = vim.api.nvim_get_current_buf()
    local class_name = call_execute_query(query_list_for_class)
    if class_name:find("Factory") then
      instantiation_list = find_factory_instantiations(instantiation_list, query_list_for_methods, bufnr)
    else
      table.insert(instantiation_list, v)
    end
  end
  return instantiation_list
end

N.show_class_instantiation = function()
  local current_class_name, rg_hit = find_class_name_and_rg_hit(query_for_class)
  local accumulated_rg_hits = rg_hit
  find_subclasses_rec(current_class_name, accumulated_rg_hits)
  vim.cmd("normal! mB")

  local instantiation_list = {}
  for _, rg_hit in ipairs(accumulated_rg_hits) do
    local class_name = class_name_from_rg_hit(rg_hit)
    if class_name ~= nil then
      local search_text = "(?:return\\s+|[A-Za-z_]\\w*\\s*=\\s*)\\b"..class_name.."\\b"
      local hits = find_with_rg_from_str(search_text)
      local filtered_hits = filter_rg_hits(hits, "tests")
      local instantiations_for_single = find_instantiations(filtered_hits)
      vim.list_extend(instantiation_list, instantiations_for_single)
    end
  end

  vim.cmd("normal! `B")
  latest_instantiation_list = instantiation_list
  latest_search_type = "class"
  show_picker("Find instantiations", instantiation_list)
end

return N

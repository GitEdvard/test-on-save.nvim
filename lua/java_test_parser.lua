-- Relies on the convention that test classes starts or ends with 
-- the string "Test"
local M = {}

-- fetch project root dir
local root_dir = vim.fs.dirname(vim.fs.find({'.gradlew', '.git', 'mvnw'}, { upward = true })[1])
local java_dir = root_dir .. "/src/main/java/"
local test_dir = root_dir .. "/src/test/java/"
local dir_list = {}

local build_env = function()
  -- execute a os find dir command in java_dir and test_dir
  local command = "find -type d"

  local dir_list_raw = {}
  local job_id = vim.fn.jobstart(command, {
    stdout_buffered = true,
    cwd = java_dir,
    on_stdout = function(_, data)
      if not data then
        return
      end
      vim.list_extend(dir_list_raw, data)
    end
  })
  vim.fn.jobwait({job_id})

  job_id = vim.fn.jobstart(command, {
    stdout_buffered = true,
    cwd = test_dir,
    on_stdout = function(_, data)
      if not data then
        return
      end
      vim.list_extend(dir_list_raw, data)
    end
  })
  vim.fn.jobwait({job_id})

  -- remove empty entries, and trim for . and ./
  local dir_list_dupl = {}
  for _, v in ipairs(dir_list_raw) do
    if v ~= nil and #v > 0 then
      local sub1 = string.gsub(v, "%./", "")
      local sub2 = string.gsub(sub1, "%.", "")
      if sub2 ~= nil and #sub2 > 0 then
        table.insert(dir_list_dupl, sub2)
      end
    end
  end

  -- Remove duplicates, create hash dict
  for _,v in ipairs(dir_list_dupl) do
    local u = v .. "/"
    if (not dir_list[u]) then
      dir_list[u] = true
    end
  end
end

build_env()

M.parse_row = function(row)
  local file_reference = string.match(row, '(at )%.*')
  if file_reference == nil then
    return row
  end
  local java_path, file_name, row_number = string.match(row, '([%.%a%d%$]*)%(([%.%a%d]+):(%d+)')
  local base_name = string.match(file_name, '([%a%d]+)%.')
  local test_match_leading = string.match(base_name, '^(Test)%.*')
  local test_match_end = string.match(base_name, '%.*(Test)$')
  local src_path = java_dir
  if test_match_leading ~= nil or test_match_end ~= nil then
    src_path = test_dir
  end
  local path_truncated = string.match(java_path, '([%.%a%d]+)%.' .. base_name)
  local os_transformed_path = "/"
  if path_truncated ~= nil then
    os_transformed_path = string.gsub(path_truncated, "%.", "/") .. "/"
  end
  if (not dir_list[os_transformed_path]) and os_transformed_path ~= "/" then
    return nil
  end
  local parsed_row = "at " .. src_path .. os_transformed_path .. file_name .." (" .. row_number .. ")"
  return parsed_row
end

return M

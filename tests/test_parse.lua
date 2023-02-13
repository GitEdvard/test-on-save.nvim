-- print out project root dir
local root_dir = vim.fs.dirname(vim.fs.find({'.gradlew', '.git', 'mvnw'}, { upward = true })[1])
P(root_dir)
local java_dir = root_dir .. "/src/main/java/"
local test_dir = root_dir .. "/src/test/java/"
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

-- Remove duplicates
local hash = {}
local dir_list = {}

for _,v in ipairs(dir_list_dupl) do
   if (not hash[v]) then
       dir_list[#dir_list+1] = v
       hash[v] = true
   end

end
print("output:")
P(dir_list)

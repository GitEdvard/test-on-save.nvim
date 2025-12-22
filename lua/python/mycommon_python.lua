local Job = require('plenary.job')

local M = {}

M.find_subclasses_from_class = function(super_class_name)
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

M.class_name_from_rg_hit = function(single_rg_hit)
  local class_name_cand2 = single_rg_hit:match(".*class (.*)%(.*%).*")
  if class_name_cand2 ~= nil then 
    return class_name_cand2
  end
  local class_name_cand1 = single_rg_hit:match(".*class (.*):")
  return class_name_cand1
end

find_subclasses_rec2 = function(root_class, rg_hits, hits_with_subclasses)
  local hits = M.find_subclasses_from_class(root_class)
  if #hits > 0 then
    table.insert(hits_with_subclasses, root_class)
  end
  for _, single_rg_hit in pairs(hits) do
    table.insert(rg_hits, single_rg_hit)
    local class_name = M.class_name_from_rg_hit(single_rg_hit)
    local class_name_trimmed = class_name:gsub("%s+", "")
    find_subclasses_rec2(class_name_trimmed, rg_hits, hits_with_subclasses)
  end
  return rg_hits
end


return M

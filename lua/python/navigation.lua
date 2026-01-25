local M = {}

local goto_next_class = function()
  local api = vim.api
  api.nvim_feedkeys("]pc", "m", false)  -- "m" = remap allowed (use mapping)
end

local goto_previous_class = function()
  local api = vim.api
  api.nvim_feedkeys("[pc", "m", false)  -- "m" = remap allowed (use mapping)
end

M.goto_next_class = function()
  vim.cmd.normal("m'")
  goto_next_class()
  vim.keymap.set("n", ",", goto_next_class)
  vim.keymap.set("n", ";", goto_previous_class)
end

M.goto_previous_class = function()
  vim.cmd.normal("m'")
  goto_previous_class()
  vim.keymap.set("n", ";", goto_next_class)
  vim.keymap.set("n", ",", goto_previous_class)
end

return M

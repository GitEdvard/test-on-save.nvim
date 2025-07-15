local M = {}

local to_vim_script_arr = require'utils'.to_vim_script_arr

local move_cursor = function(prompt_win, nrrows)
    local pos, _ = vim.api.nvim_win_get_cursor(prompt_win)
    local new_line = pos[1] + nrrows
    vim.api.nvim_win_set_cursor(prompt_win, {new_line, 0})
end

local create_new_concole_window = function()
    local original_win = vim.api.nvim_get_current_win()
    vim.cmd.vnew()
    -- Make it a scratch buffer
    vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = 0, silent = true, noremap = true })
    vim.cmd{cmd = "setlocal", args = {"buftype=nofile"}}
    vim.cmd{cmd = "setlocal", args = {"bufhidden=hide"}}
    vim.cmd{cmd = "setlocal", args = {"noswapfile"}}
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_name(bufnr, "Console")
    prompt_win = vim.api.nvim_get_current_win()
    -- vim.api.nvim_set_current_win(original_win)
    return bufnr, prompt_win
end

local show_console_window = function()
  local bufnr = vim.fn.bufnr("Console")
  vim.cmd.vnew()
  vim.cmd.buffer(bufnr)
  prompt_win = vim.api.nvim_get_current_win()
  return bufnr, prompt_win
end

local spawn_console_window_silent = function()
  local res = vim.fn.bufname("Console")
  if res == "Console" then
    return show_console_window()
  else
    return create_new_concole_window()
  end
end

local show_and_gather_err = function(data, err_output, parser)
    if not data then
        return err_output
    end
    for _, row in ipairs(data) do
      if parser ~= nil then
        parsed_row = parser(row)
      else
        parsed_row = row
      end
      if parsed_row ~= nil then
        table.insert(err_output, parsed_row)
      end
    end
    return err_output
end

local show_errors = function(err_output, bufnr, prompt_win)
    local vim_script_arr = to_vim_script_arr(err_output)
    vim.cmd { cmd = 'cgetexpr', args = {vim_script_arr} }
    vim.cmd { cmd = 'copen'}
    local c_w = vim.api.nvim_replace_termcodes('<C-w>', true, false, true)
    vim.api.nvim_feedkeys(c_w .. 'L', 'n', false)
end

M.run_test = function(command, parser)
    local err_output = {}
    local ret = vim.fn.jobstart(command, {
        stdout_buffered = true,
        on_stdout = function(_, data)
            err_output = show_and_gather_err(data, err_output, parser)
        end,
        on_stderr = function(_, data)
            err_output = show_and_gather_err(data, err_output, parser)
        end,
        on_exit = function(_, exit_code, _)
            show_errors(err_output, bufnr, prompt_win)
        end
    })
end

return M

local M = {}

local to_vim_script_arr = require'utils'.to_vim_script_arr

local move_cursor = function(prompt_win, nrrows)
    local pos, _ = vim.api.nvim_win_get_cursor(prompt_win)
    local new_line = pos[1] + nrrows
    vim.api.nvim_win_set_cursor(prompt_win, {new_line, 0})
end

local spawn_scratch_window = function()
    local original_win = vim.api.nvim_get_current_win()
    vim.cmd.vnew()
    -- Make it a scratch buffer
    vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = 0, silent = true, noremap = true })
    vim.cmd{cmd = "setlocal", args = {"buftype=nofile"}}
    vim.cmd{cmd = "setlocal", args = {"bufhidden=hide"}}
    vim.cmd{cmd = "setlocal", args = {"noswapfile"}}
    local bufnr = vim.api.nvim_get_current_buf()
    local prompt_win = vim.api.nvim_get_current_win()
    -- vim.api.nvim_set_current_win(original_win)
    return bufnr, prompt_win
end

local show_and_gather_err = function(data, err_output, bufnr, prompt_win, parser)
    if not data then
        return err_output
    end
    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, data)
    move_cursor(prompt_win, #data)
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
    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, {"Output written to the quickfix."})
    move_cursor(prompt_win, 1)
    local vim_script_arr = to_vim_script_arr(err_output)
    vim.cmd { cmd = 'cgetexpr', args = {vim_script_arr} }
end

M.run_test = function(command, parser)
    local bufnr, prompt_win = spawn_scratch_window()
    local err_output = {}
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "Waiting for script output ..."})
    vim.fn.jobstart(command, {
        stdout_buffered = true,
        on_stdout = function(_, data)
            err_output = show_and_gather_err(data, err_output, bufnr, prompt_win, parser)
        end,
        on_stderr = function(_, data)
            err_output = show_and_gather_err(data, err_output, bufnr, prompt_win, parser)
        end,
        on_exit = function(_, exit_code, _)
            show_errors(err_output, bufnr, prompt_win)
        end
    })
end

return M

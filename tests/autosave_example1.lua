-- :echo nvim_get_current_buf()
local bufnr = 50
vim.api.nvim_create_autocmd("BufWritePost", {
    group = vim.api.nvim_create_augroup("edvardwritebuf", { clear = true }),
    pattern = "hello.py",
    callback = function()
        vim.fn.jobstart({ "python3", "hello.py" }, {
            stdout_buffered = true, -- print whole lines
            on_stdout = function(_, data)
                if data then
                    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, data)
                end
            end,
            on_stderr = function(_, data)
                if data then
                    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, data)
                end
            end,
        })
    end,
})

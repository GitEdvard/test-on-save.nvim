local group = vim.api.nvim_create_augroup("edvard-automagic", { clear = true })

local attach_to_buffer = function(bufnr, command)
    vim.api.nvim_create_autocmd("BufWritePost", {
        group = group,
        pattern = "*.cs",
        callback = function()
            -- vim.cmd("make")
            vim.fn.jobstart(command, {
                stdout_buffered = true,
                on_stdout = function(_, data)
                    if not data then
                        return
                    end
                    local str_data = table.concat(data, "\n")
                    vim.cmd { cmd = 'cexpr', args = {vim.inspect(str_data)} }
                end
            })
        end,
    } )
end

vim.api.nvim_create_user_command("RunUnit", function()
    -- attach_to_buffer(vim.api.nvim_get_current_buf(), { "dotnet", "test" })
    attach_to_buffer(vim.api.nvim_get_current_buf(), { "dotnet", "test" })
end, {})

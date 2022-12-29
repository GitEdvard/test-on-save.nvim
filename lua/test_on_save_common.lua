local query_module = require'vim.treesitter.query'
local ts_utils = require'nvim-treesitter.ts_utils'
local ts = require'vim.treesitter'

-- Trim spaces and opening brackets from end
local transform_line = function(line)
    return line:gsub('%s*[%[%(%{]*%s*$', '')
end

local matches_pattern = function(node, type_patterns)
    local node_type = node:type()
    local is_valid = false
    local matching_pattern = ""
    for rgx in pairs(type_patterns) do
        if node_type:find(rgx) then
            is_valid = true
            matching_pattern = rgx
            break
        end
    end
    return is_valid, matching_pattern
end

local get_node_text = function(start_node, bufnr, query_string, lang)
    local query = ts.parse_query(lang, query_string)
    for id, node in query:iter_captures(start_node, bufnr, 0, -1) do
        if id == 1 then
            return query_module.get_node_text(node, bufnr)
        end
    end
    return nil
end

function get_unit_test_range(bufnr, type_patterns, lang)
    local options = {}
    local indicator_size = 100
    local transform_fn = transform_line
    local current_node = ts_utils.get_node_at_cursor()
    if not current_node then return "" end
    local lines = {}
    local expr = current_node
    while expr do
        local matches, matching_pattern = matches_pattern(expr, type_patterns)
        if matches then
            local method_node = expr
            local text = get_node_text(method_node, bufnr, type_patterns[matching_pattern], lang)
            table.insert(lines, 1, text)
        end
        expr = expr:parent()
    end
    text = table.concat(lines, ".")
    return text
end

local attach_test_range = function(bufnr, command, pattern)
    local group = vim.api.nvim_create_augroup("edvard-automagic", { clear = true })
    vim.api.nvim_create_autocmd("BufWritePost", {
        group = group,
        pattern = pattern,
        callback = function()
            vim.fn.jobstart(command, {
                stdout_buffered = true,
                on_stdout = function(_, data)
                    if not data then
                        return
                    end
                    -- convert data to a vim script array
                    local data_vim_arr = '[\'' .. table.concat(data, '\',\'') .. '\']'
                    vim.cmd { cmd = 'cgetexpr', args = {data_vim_arr} }
                end,
            } )
        end
    })
end

return attach_test_range

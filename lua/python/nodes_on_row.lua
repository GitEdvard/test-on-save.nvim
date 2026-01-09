local U = require'python.my_utils'

-- Collect all Tree-sitter nodes that cover the current line (row).
-- Rows are 0-based in the Tree-sitter API.
local ts = vim.treesitter

local function nodes_on_line(bufnr, row0)
  bufnr = bufnr or 0
  -- Convert the cursor row (1-based) to 0-based for Tree-sitter.
  row0 = (row0 ~= nil) and row0 or (vim.api.nvim_win_get_cursor(0)[1] - 1)

  local parser = ts.get_parser(bufnr)
  local results = {}

  -- Iterate all trees (main language + any injected languages)
  for _, tree in ipairs(parser:parse()) do
    local root = tree:root()

    local function visit(node)
      local sr, sc, er, ec = node:range()
      -- Only traverse into nodes that overlap the target row.
      if row0 < sr or row0 > er then
        return
      end
      table.insert(results, node)
      for child in node:iter_children() do
        visit(child)
      end
    end

    visit(root)
  end

  return results
end

-- -- Example: print the node types that cover the current line
-- for _, n in ipairs(nodes_on_line(0)) do
--   print(n:type())
-- end


-- Get nodes by query on a single line (row)
local function nodes_on_line_by_query(bufnr, row0, query_str)
  bufnr = bufnr or 0
  row0 = (row0 ~= nil) and row0 or (vim.api.nvim_win_get_cursor(0)[1] - 1)
  print("row0: "..row0)

  local parser = vim.treesitter.get_parser(bufnr)
  local lang = parser:lang()                    -- primary language for the buffer
  local query = vim.treesitter.query.parse(lang, query_str)

  local nodes = {}
  for _, tree in ipairs(parser:parse()) do
    local root = tree:root()
    for _, node, _ in query:iter_captures(root, bufnr, row0, row0 + 1) do
      table.insert(nodes, node)
    end
  end
  return nodes
end

-- Example: capture all identifiers on the current line
-- local ids = nodes_on_line_by_query(0, nil, [[(identifier) @id]])
-- for _, n in ipairs(ids) do
--   print(n:type())
-- end

local M = {}

M.nodes_on_line = function()
  -- local ids = nodes_on_line_by_query(0, nil, [[(identifier) @id]])
  local classes = nodes_on_line_by_query(0, nil, U.query_for_class)
  local methods = nodes_on_line_by_query(0, nil, U.query_for_function)
  for _, n in ipairs(classes) do
    print("class:")
    print(n:type())
  end
  for _, n in ipairs(methods) do
    print("method:")
    print(n:type())
  end
end

return M

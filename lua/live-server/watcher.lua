local uv = vim.loop
local M = {}

function M.watch(dir, on_change)
  local handle = uv.new_fs_event()

  handle:start(dir, { recursive = true }, function(err, filename)
    if err then return end
    if not filename then return end

    on_change(filename)
  end)
end

return M

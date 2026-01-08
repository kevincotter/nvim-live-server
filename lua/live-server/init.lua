local server = require("live-server.server")
local watcher = require("live-server.watcher")

local M = {}

M.opts = {
  host = "0.0.0.0",
  port = 8080,
}

---@class live_server.Opts
---@field port integer
---@field host string

---@param opts live_server.Opts
function M.setup(opts) M.opts = vim.tbl_deep_extend("force", M.opts, opts) end

function M.start()
  local root = vim.fn.getcwd()

  server.start(root, M.opts)
  watcher.watch(root, function() server.reload() end)
  vim.cmd("redrawstatus")
end

function M.stop()
  server.stop()
  vim.cmd("redrawstatus")
end

function M.toggle()
  if server.running then
    M.stop()
  else
    M.start()
  end
end

return M

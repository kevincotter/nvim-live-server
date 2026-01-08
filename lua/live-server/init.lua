local server = require("live-server.server")
local watcher = require("live-server.watcher")
local inject = require("live-server.inject")

local M = {}

M.opts = {
  host = "0.0.0.0",
  port = 8080,
}

function M.setup(opts) M.opts = vim.tbl_deep_extend("force", M.opts, opts or {}) end

function M.start()
  local root = vim.fn.getcwd()
  local host = M.opts.host
  local port = M.opts.port

  server.start(root, inject.inject, M.opts)
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

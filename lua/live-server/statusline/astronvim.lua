M = {}

local server = require("live-server.server")

function M.live_server_provider(opts)
  opts = opts or {}
  local text ---@type string
  local action ---@type string
  if server.running then
    text = "󰙧 Port: " .. tostring(server.port)
    action = "%@v:lua.require'live-server'.stop@"
  else
    text = "󰀂 Go Live"
    action = "%@v:lua.require'live-server'.start@"
  end
  return action .. require("astroui.status.utils").stylize(text, opts)
end

return M

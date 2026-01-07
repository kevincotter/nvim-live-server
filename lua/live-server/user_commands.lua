local M = {}

function M.register()
  vim.api.nvim_create_user_command("LiveServerStart", function()
    require("live-server").start()
  end, { desc = "Start Live Server" })

  vim.api.nvim_create_user_command("LiveServerStop", function()
    require("live-server").stop()
  end, { desc = "Stop Live Server" })

  vim.api.nvim_create_user_command("LiveServerToggle", function()
    require("live-server").toggle()
  end, { desc = "Toggle Live Server" })
end

return M

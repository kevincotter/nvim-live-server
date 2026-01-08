local uv = vim.uv or vim.loop
local M = {}

local function simple_watch(dir, on_change, recursive)
  local handle = uv.new_fs_event()

  if not handle then
    vim.notify("Error setting up watcher")
    return
  end

  handle:start(dir, { recursive = recursive }, function(err, filename)
    if err then
      vim.notify("File watching error")
      return
    end
    if not filename then return end

    local file_path = dir .. '/' .. (filename or "")
    on_change(file_path)
  end)
end

local function linux_watch(root_dir, on_change)
  local handle = simple_watch(root_dir, on_change)
  local scanner = uv.fs_scandir(root_dir)
  if scanner then
    while true do
      local name, type = uv.fs_scandir_next(scanner)
      if not name then break end
      if type == 'directory' then
        local sub = root_dir .. '/' .. name
        simple_watch(sub, on_change)
      end
    end
  end
end

function M.watch(dir, on_change)
  -- linux doesn't support recursive file watching
  -- (https://www.reddit.com/r/neovim/comments/1gchaus/recursive_directory_watching/)
  -- But you can watch a lot of dirs with quite a good performance
  -- cat /proc/sys/fs/inotify/max_user_watches --> 524288
  -- this might seem small but even the largest project I could find with node_modules
  -- included had 13k dirs. It should be ok. Maybe later add option to exclude dirs.
  if uv.os_uname().sysname == 'Linux' then
    linux_watch(dir, on_change)
  end
  simple_watch(dir, on_change, true)
end

return M

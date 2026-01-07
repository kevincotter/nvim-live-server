# NVIM Live Server

A simple HTTP server with live reload for HTML, CSS, JS files written in **just lua**.

> [!WARNING]  
> This plugin is experimental! It works for simple use-cases but might break with more complex ones!



https://github.com/user-attachments/assets/8dba8842-a7a8-4374-a7ee-f15e1893e3f5


## Features:

- Extremely light (Less than 400 lines of code!)
- No dependencies (Aside NVIM ofc)
- Blazingly fast 🚀 (Starts and serves in less than milisecond!)
- Start or Stop server by a single click from status bar.
- Automatic free port detection

## Installation

### Lazy:

```lua
{
  "hyperstown/nvim-live-server",
  cmd = { "LiveServerStart", "LiveServerStop", "LiveServerToggle"},
  lazy = false,
  opts = {
    port = 5550, -- optional, default 8080
  },
},
```

### Manual

```lua
require('live-server').setup(opts)
```

## Usage:

You can either start the server with `LiveServerStart` or `LiveServerToggle`,
for stopping is either `LiveServerStop` or `LiveServerToggle`.

You can also click the icon on status bar to toggle the server.

## Integration with status line

### NvChad

```lua
M.ui = {
  statusline = {
    modules = {
	  live_server = require("live-server.statusline.nvchad").render
    },
    order = { "mode", "file", "git", "%=", "lsp_msg", "live_server", "diagnostics", "lsp", "cwd" } -- "live_server" is our live server module here
  }
}
```

### AstroNVIM

```lua
return {
  "rebelot/heirline.nvim",
  opts = function(_, opts)
    local status = require("astroui.status")
    opts.statusline = { -- statusline
      hl = { fg = "fg", bg = "bg" },
      status.component.mode(),
      status.component.git_branch(),
      status.component.file_info(),
      status.component.git_diff(),
      status.component.diagnostics(),
      status.component.fill(),
      status.component.cmd_info(),
      status.component.fill(),
      status.component.lsp(),
      status.component.virtual_env(),
      -- here we put our live-server module
      status.component.builder({
        { provider = require('live-server.statusline.astronvim').live_server_provider },
      }),
      status.component.treesitter(),
      status.component.nav(),
      status.component.mode()
    }
  end,
}
```

## How it works?

This server makes use of
[SSE](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events)
instead of relying on websockets. So theres no need for implementing
whole websockets spec. SEE events are way less sophisticated than webstockets but are way more than enough for live reload server. \
HTTP server was implemented using `vim.loop.new_tcp()`. It's a very simple implementation of HTTP and it should be used only for development.

## Why?

I found a few plugins that already provide Live Server functionality
even with realtime edits but for me every package was either too complex or it depended on some npm package or it was no longer maintained.

## Planned features

- Seamless CSS reload
- Directory browser
- Improved code injection
- Healthcheck

## Acknowledgements

1. [ritwickdey/vscode-live-server](https://github.com/ritwickdey/vscode-live-server) - The project I took inspiration from. The goal is to recreate same basic functionality in NVIM.
2. [barrettruth/live-server.nvim](https://github.com/barrettruth/live-server.nvim) - Another project I took inspiration from, however it still depends on npm live-server package.
3. [linux-cultist/venv-selector.nvim](https://github.com/linux-cultist/venv-selector.nvim/) - Plugin structure and status line integration

## Contributions

Are more than welcome. Just remember to keep project simple.

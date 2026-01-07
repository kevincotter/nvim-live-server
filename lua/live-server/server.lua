local M = {}

local server
local root_dir
local inject_fn

M.sse_clients = {}

-- https://mimetype.io/all-types
local mime_types = {
  html = "text/html",
  htm = "text/html",
  css = "text/css",
  png = "image/png",
  gif = "image/gif",
  avif = "image/avif",
  webp = "image/webp",
  apng = "image/apng",
  txt = "text/plain",
  woff = "font/woff",
  woff2 = "font/woff2",
  jpg = "image/jpeg",
  jpeg = "image/jpeg",
  svg = "image/svg+xml",
  ico = "image/x-icon",
  pdf = "application/pdf",
  json = "application/json",
  js = "application/javascript",
}

local function get_mime_type(path)
  local ext = path:match("%.([^./]+)$")
  return mime_types[ext] or "application/octet-stream"
end

local function html_response(text)
  return "<!DOCTYPE html><html><body>" .. text .. "</body></html>"
end

local function send(client, status, headers, body)
  local lines = { "HTTP/1.1 " .. status }
  for k, v in pairs(headers) do
    table.insert(lines, k .. ": " .. v)
  end
  table.insert(lines, "")
  table.insert(lines, body or "")

  client:write(table.concat(lines, "\r\n"))
end

-- -----------------------------
-- HANDLE REQUEST
-- -----------------------------
local function handle_request(client, raw)
  local method, path = raw:match("(%w+)%s+([^%s]+)")
  if method ~= "GET" then
    send(client, "405 Method Not Allowed", {
      ["Content-Type"] = "text/plain",
    }, html_response("Method Not Allowed"))
    client:close()
    return
  end
  if not path then
    client:close()
    return
  end

  if path == "/__live_reload" then
    client:write(table.concat({
      "HTTP/1.1 200 OK",
      "Content-Type: text/event-stream",
      "Cache-Control: no-cache",
      "Connection: keep-alive",
      "",
    }, "\r\n"))

    table.insert(M.sse_clients, client)
    return
  end

  if path:sub(-1) == "/" then
    path = path .. "index.html"
  end

  local file_path = root_dir .. path
  local file = io.open(file_path, "rb")

  if not file then
    send(client, "404 Not Found", {
      ["Content-Type"] = "text/html",
    }, html_response("Not Found"))
    client:close()
    return
  end

  local body = file:read("*a")
  file:close()
  if not body then
    send(client, "404 Not Found", {
      ["Content-Type"] = "text/html",
    }, html_response("Not Found"))
    client:close()
    return
  end

  local mime = get_mime_type(path)

  if mime == "text/html" and inject_fn then
    body = inject_fn(body, path)
  end

  send(client, "200 OK", {
    ["Content-Type"] = mime,
    ["Content-Length"] = #body,
    ["Cache-Control"] = "no-cache",
  }, body)

  client:close()
end

local function is_port_busy(port)
  local uv = vim.uv or vim.loop
  local client = uv.new_tcp()
  if not client then
    return false, "Failed to create TCP client"
  end

  local busy = false
  local done = false

  client:connect("127.0.0.1", port, function(err)
    if not err then
      busy = true
    end
    done = true
    client:close()
  end)

  -- Process events until done (typically instant for local checks)
  while not done do
    uv.run("once")
  end

  return busy
end

local function find_free_port(start)
  local port = start
  local max_tries = 20

  for _ = 1, max_tries do
    local ok = not is_port_busy(port)
    if ok then
      return port
    end
    vim.notify("Port " .. tostring(port) .. " is busy, trying another", vim.log.levels.WARN)
    port = port + 1
  end

  return nil
end

-- -----------------------------
-- PUBLIC API
-- -----------------------------
function M.start(root, port, inject)
  local start = vim.loop.hrtime()
  if M.running then
    vim.notify("Live server already running!", vim.log.levels.WARN)
    return
  end

  inject_fn = inject
  root_dir = root

  local free_port = find_free_port(port)
  if not free_port then
    vim.notify("No free port found", vim.log.levels.ERROR)
    return
  end

  server = vim.loop.new_tcp()
  if not server then
    vim.notify("tcp error", vim.log.levels.error)
    return
  end
  local ok, err = pcall(server.bind, server, "0.0.0.0", free_port)
  if not ok then
    vim.notify("Failed to bind server: " .. tostring(err), vim.log.levels.ERROR)
    return
  end

  server:listen(128, function(err)
    assert(not err)
    local client = vim.loop.new_tcp()
    if not client then
      vim.notify("tcp error", vim.log.levels.error)
      return
    end
    server:accept(client)
    client:read_start(function(_, data)
      if not data then
        for i = #M.sse_clients, 1, -1 do
          if M.sse_clients[i] == client then
            table.remove(M.sse_clients, i)
            break
          end
        end
        client:close()
        return
      end
      handle_request(client, data)
    end)
  end)

  M.running = true
  M.port = free_port
  local elapsed_ms = (vim.loop.hrtime() - start) / 1e6
  vim.notify("Server started in " .. string.format("%.3f ms", elapsed_ms) .. " at http://0.0.0.0:" .. free_port)
end

function M.stop()
  if server then
    server:close()
    server = nil
  end
  M.running = false
  M.sse_clients = {}
  vim.notify("Live server stopped")
end

function M.reload()
  for i = #M.sse_clients, 1, -1 do
    local client = M.sse_clients[i]
    local ok = pcall(function()
      client:write("data: reload\n\n")
    end)

    if not ok then
      table.remove(M.sse_clients, i)
    end
  end
end

return M

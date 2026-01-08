local M = {}

local snippet = [[
<!--  Code injected by nvim-live-server -->
<script>
(() => {
  const es = new EventSource("/__live_reload");

  // When the page is about to reload or navigate
  window.addEventListener("beforeunload", () => {
    es.close(); // explicitly close SSE
  });

  // Reload when SSE message arrives
  es.onmessage = () => location.reload();
})();
</script>
]]

function M.inject(html, path)
  if not string.find(html, "</body>") then
    vim.notify("Live reload is not supported without a body tag", vim.log.levels.WARN)
    return false
  end
  if path:match("%.html$") then return html:gsub("</body>", snippet .. "\n</body>") end
  return html
end

return M

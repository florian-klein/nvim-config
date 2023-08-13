--@type MappingsTable
local M = {}

M.ignore = {}

M.general = {
  n = {
    [";"] = { ":", "enter command mode", opts = { nowait = true } },
    ["<C-s>"] = { ":lua vim.lsp.buf.format()<CR>:w<CR>", "format and save file" },
  },
  v = {
    ["<TAB>"] = { ">gv", "shift selected text right" },
  }
}

return M;


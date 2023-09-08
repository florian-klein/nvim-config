--@type MappingsTable
local M = {}

M.ignore = {}

M.general = {
  n = {
    [";"] = { ":", "enter command mode", opts = { nowait = true } },
    ["<C-s>"] = { ":lua vim.lsp.buf.format()<CR>:w<CR>", "format and save file" },
    ["<leader>gb"] = { "<cmd> Telescope git_branches <CR>", "Git branches" },
  },
  v = {
    ["<TAB>"] = { ">gv", "shift selected text right" },
  }
}

return M;


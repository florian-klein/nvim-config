--@type MappingsTable
local M = {}

M.ignore = {}

M.general = {
  n = {
    [";"] = { ":", "enter command mode", opts = { nowait = true } },
    ["<C-s>"] = { ":lua vim.lsp.buf.format()<CR>:w<CR>", "format and save file" },
    ["<leader>gb"] = { "<cmd> Telescope git_branches <CR>", "Git branches" },
    ["<leader>xx"] = { "<cmd>lua require('trouble').toggle()<CR>", "Trouble" },
    ["<leader>xw"] = { "<cmd>lua require('trouble').toggle('workspace_diagnostics')<CR>", "Workspace Diagnostics" },
    ["<leader>xd"] = { "<cmd>lua require('trouble').toggle('document_diagnostics')<CR>", "Document Diagnostics" },
    ["<leader>xq"] = { "<cmd>lua require('trouble').toggle('quickfix')<CR>", "Quickfix" },
    ["<leader>xl"] = { "<cmd>lua require('trouble').toggle('loclist')<CR>", "Loclist" },
    ["gR"] = { "<cmd>lua require('trouble').toggle('lsp_references')<CR>", "LSP References" },
  },
  v = {
    ["<TAB>"] = { ">gv", "shift selected text right" },
    ["<S-TAB>"] = { "<gv", "shift selected text left" },
  }
}

return M;


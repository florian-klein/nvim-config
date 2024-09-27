--@type MappingsTable
local M = {}

M.ignore = {}

M.general = {
  n = {
    [";"] = { ":", "enter command mode", opts = { nowait = true } },
    ["<C-s>"] = { ":lua vim.lsp.buf.format()<CR>:w<CR>", "format and save file" },
    ["<leader>gb"] = { "<cmd> Telescope git_branches <CR>", "Git branches" },
    ["<leader>xx"] = { "<cmd>Trouble diagnostics toggle focus=true<cr>", "Trouble" },
    ["<leader>qf"] = { "<cmd>Trouble qflist toggle<cr>", "View Quickfix Options" },
    ["<leader>xd"] = { "<cmd>lua require('trouble').toggle('document_diagnostics')<CR>", "Document Diagnostics" },
    ["<leader>xq"] = { "<cmd>lua require('trouble').toggle('quickfix')<CR>", "Quickfix" },
    ["<leader>xl"] = { "<cmd>lua require('trouble').toggle('loclist')<CR>", "Loclist" },
    ["<leader>a"] = {"<cmd>AerialToggle!<CR>"},
    ["<C-m>"] = {"<cmd>AerialPrev<CR>"},
    ["<C-n>"] = { ":cnext<CR>", "Next quickfix item" },
    ["<C-p>"] = { ":cprev<CR>", "Previous quickfix item" },
    ["<leader>cf"] = { ":cfirst<CR>", "First quickfix item" },
    ["<leader>cl"] = { ":clast<CR>", "Last quickfix item" },
    ["<C-M>"] = {"<cmd>AerialNext<CR>"},
    ["gR"] = { "<cmd>lua require('trouble').toggle('lsp_references')<CR>", "LSP References" },
    -- ["f"] = { "<cmd>lua require('leap').leap({target_windows = {vim.fn.win_getid()}})<CR>", "Leap forward" },
    -- ["F"] = { "<cmd>lua require('leap').leap({target_windows = {vim.fn.win_getid()}, backward = true})<CR>", "Leap backward" },
  },
  v = {
    ["<TAB>"] = { ">gv", "shift selected text right" },
    ["<S-TAB>"] = { "<gv", "shift selected text left" },
  }
}

return M;

